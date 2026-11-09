//
//  StoreManager.swift
//  Renting
//
//  StoreKit 2. One product: "Renting Cloud", an auto-renewing monthly subscription. While it is
//  active it unlocks everything the free plan does not have (see `Plan.swift`): unlimited homes,
//  the advanced home, tenant and fiscal tools, rent receipts, alerts, no ads and iCloud sync.
//  There is no one-time purchase.
//
//  The ad layer reads the ad-free flag synchronously from UserDefaults at launch (before
//  StoreKit has loaded anything), so entitlements are mirrored there.
//

import StoreKit
import SwiftUI

/// What the active subscription looks like, for the settings and paywall screens.
struct CloudPlan: Equatable {
    var renews: Bool
    var expires: Date?
    var isTrial: Bool
    var inGracePeriod: Bool
}

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    static let cloudID = "com.albeasystems.renting.cloud.monthly"
    /// The three flags below are the subscription, mirrored for the views (`@AppStorage`) and for
    /// the ad layer, which reads it before StoreKit has answered. They always change together.
    /// Read by the ad layer: the subscription removes ads.
    static let adFreeKey = "isPremiumUnlocked"
    /// "Has the paid features" (advanced tools, receipts, alerts, unlimited homes).
    static let proKey = "isProUnlocked"
    static let cloudKey = "isCloudActive"
    /// Set by the hidden "tap the version 10 times" unlock (see `SettingsView`): the subscription, for testing.
    static let testUnlockKey = "proTestUnlock"

    /// The hidden unlock only exists in development and TestFlight builds. In an
    /// App Store build it would be a way around the purchase (and a hidden feature
    /// App Review rejects), so it is inert there.
    static var testUnlockAllowed: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    static var testUnlockActive: Bool { testUnlockAllowed && UserDefaults.standard.bool(forKey: testUnlockKey) }

    private(set) var cloudProduct: Product?
    /// The subscription is active (including a free trial and a billing grace period).
    private(set) var hasCloud = UserDefaults.standard.bool(forKey: cloudKey)
    private(set) var cloudPlan: CloudPlan?
    /// The free trial of the subscription is offered to this user, in days.
    private(set) var trialDays: Int?
    private(set) var isPurchasing = false
    private(set) var purchaseMessage: LocalizedStringKey?

    private var updatesTask: Task<Void, Never>?

    private init() {}

    var cloudPriceText: String { cloudProduct?.displayPrice ?? "" }

    /// Call once at launch: listen for transactions, load products, sync entitlements.
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    /// Hidden test unlock: the subscription on or off, so that everything (including iCloud sync)
    /// can be tried on a device without buying it (no-op in App Store builds).
    /// Returns whether it ended up on.
    func toggleTestUnlock() async -> Bool {
        guard Self.testUnlockAllowed else { return false }
        let d = UserDefaults.standard
        let on = !d.bool(forKey: Self.testUnlockKey)
        d.set(on, forKey: Self.testUnlockKey)
        await refreshEntitlements()
        return on
    }

    func loadProducts() async {
        let products = (try? await Product.products(for: [Self.cloudID])) ?? []
        cloudProduct = products.first { $0.id == Self.cloudID }
        trialDays = nil
        if let sub = cloudProduct?.subscription, let offer = sub.introductoryOffer, offer.paymentMode == .freeTrial, await sub.isEligibleForIntroOffer {
            let p = offer.period
            switch p.unit {
            case .day: trialDays = p.value
            case .week: trialDays = p.value * 7
            case .month: trialDays = p.value * 30
            case .year: trialDays = p.value * 365
            @unknown default: break
            }
        }
    }

    func purchaseCloud() async { await purchase(cloudProduct) }

    private func purchase(_ product: Product?) async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        purchaseMessage = nil
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                } else {
                    purchaseMessage = "store.unverified"
                }
            case .pending:
                purchaseMessage = "store.pending"
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseMessage = "store.failed"
            #if DEBUG
            print("[Store] purchase failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Restore previous purchases on a new device / reinstall.
    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var cloud = false
        var plan: CloudPlan?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.revocationDate == nil,
                  transaction.productID == Self.cloudID else { continue }
            guard transaction.expirationDate.map({ $0 > Date() }) ?? true else { continue }
            cloud = true
            plan = CloudPlan(renews: true, expires: transaction.expirationDate, isTrial: Self.isTrial(transaction), inGracePeriod: false)
        }
        if cloud, let status = await cloudStatus() {
            plan?.renews = status.renews
            plan?.inGracePeriod = status.inGrace
        }
        cloud = cloud || Self.testUnlockActive
        hasCloud = cloud
        cloudPlan = cloud ? plan : nil

        let d = UserDefaults.standard
        d.set(cloud, forKey: Self.cloudKey)
        d.set(cloud, forKey: Self.proKey)
        d.set(cloud, forKey: Self.adFreeKey)   // the subscription includes "no ads"
        CloudSync.shared.entitlementsChanged()
    }

    private func cloudStatus() async -> (renews: Bool, inGrace: Bool)? {
        guard let statuses = try? await cloudProduct?.subscription?.status else { return nil }
        for status in statuses {
            guard status.state == .subscribed || status.state == .inGracePeriod || status.state == .inBillingRetryPeriod else { continue }
            var renews = true
            if case .verified(let info) = status.renewalInfo { renews = info.willAutoRenew }
            return (renews, status.state == .inGracePeriod || status.state == .inBillingRetryPeriod)
        }
        return nil
    }

    private static func isTrial(_ t: StoreKit.Transaction) -> Bool {
        if #available(iOS 17.2, *) { return t.offer?.type == .introductory }
        return t.offerType == .introductory
    }
}
