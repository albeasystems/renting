//
//  ProPaywallView.swift
//  Renting
//
//  The one paid plan, "Renting Cloud" (monthly subscription): unlimited homes, the advanced home,
//  tenant and fiscal tools, rent receipts, smart alerts, no ads and iCloud sync with a backup
//  (see `Plan.swift`). There is no one-time purchase. The screen shows the price, the length,
//  the free trial when there is one and the renewal terms, as App Store rules ask for
//  auto-renewing subscriptions.
//

import SwiftUI
import StoreKit

struct ProPaywallView: View {
    @State private var store = StoreManager.shared
    @State private var sync = CloudSync.shared
    @State private var showManage = false
    @Environment(\.openURL) private var openURL
    /// Why the screen was opened when a limit sent the landlord here (the free homes).
    var reason: LocalizedStringKey?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "icloud.fill").font(.system(size: 44)).foregroundStyle(Color.brand)
                    Text("pro.title").font(.largeTitle.bold())
                    Text("pro.subtitle").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                if let reason, !store.hasCloud {
                    Label(reason, systemImage: "lock.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gold.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if store.hasCloud { activeCard } else { planCard }

                if let message = store.purchaseMessage { Text(message).font(.footnote).foregroundStyle(Color.alert).multilineTextAlignment(.center) }

                VStack(spacing: 10) {
                    Button("settings.restore") { Task { await store.restore() } }.font(.footnote)
                    if !store.hasCloud { Text("pro.sub.legal").font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                    HStack(spacing: 16) {
                        Link("settings.terms", destination: AppLinks.terms)
                        Link("settings.privacy_policy", destination: AppLinks.privacyPolicy)
                    }
                    .font(.caption)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("pro.title")
        .navigationBarTitleDisplayMode(.inline)
        .manageSubscriptionsSheet(isPresented: $showManage)
        .task { if store.cloudProduct == nil { await store.loadProducts() } }
    }

    // MARK: Cards

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("cloud.plan", systemImage: "icloud.fill").font(.title3.weight(.bold)).foregroundStyle(Color.brand)
                Spacer()
                if !store.cloudPriceText.isEmpty { Text("cloud.price_month \(store.cloudPriceText)").font(.headline) }
            }
            feature("building.2.fill", .brand, "plan.f.homes.title", "plan.f.homes.text \(Plan.freeHomeLimit)")
            feature("briefcase.fill", .teal, "plan.f.homes_adv.title", "plan.f.homes_adv.text")
            feature("person.text.rectangle.fill", .indigo, "plan.f.tenants_adv.title", "plan.f.tenants_adv.text")
            feature("doc.richtext.fill", .gold, "pro.f.reports.title", "pro.f.reports.text")
            feature("bell.badge.fill", .expense, "pro.f.alerts.title", "pro.f.alerts.text")
            feature("nosign", .gray, "pro.f.ads.title", "pro.f.ads.text")
            feature("arrow.triangle.2.circlepath.icloud.fill", .brand, "cloud.f.sync.title", "cloud.f.sync.text")
            feature("externaldrive.fill.badge.icloud", .teal, "cloud.f.backup.title", "cloud.f.backup.text")

            Button { Task { await store.purchaseCloud() } } label: {
                HStack {
                    if store.isPurchasing { ProgressView().tint(.white) }
                    Text(subscribeTitle).fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent).controlSize(.large).tint(Color.brand)
            .disabled(store.isPurchasing || store.cloudPriceText.isEmpty)

            if store.cloudPriceText.isEmpty {
                Text("cloud.price_unavailable").font(.caption).foregroundStyle(.secondary)
            } else if store.trialDays != nil {
                Text("cloud.trial.then \(store.cloudPriceText)").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("cloud.cancel_any_time").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.brand.opacity(0.5), lineWidth: 1.5))
    }

    private var subscribeTitle: LocalizedStringKey {
        if store.cloudPriceText.isEmpty { return "cloud.subscribe_plain" }
        if let days = store.trialDays { return "cloud.trial \(days)" }
        return "cloud.subscribe \(store.cloudPriceText)"
    }

    private var activeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("cloud.active", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(Color.income)
            if let plan = store.cloudPlan {
                if plan.isTrial { Text("cloud.active.trial").font(.subheadline) }
                if plan.inGracePeriod {
                    Label("cloud.active.grace", systemImage: "exclamationmark.triangle.fill").font(.footnote).foregroundStyle(Color.expense)
                } else if let end = plan.expires {
                    Text(plan.renews ? "cloud.active.renews \(end.short)" : "cloud.active.ends \(end.short)").font(.footnote).foregroundStyle(.secondary)
                }
            }
            Text("cloud.active.includes").font(.footnote).foregroundStyle(.secondary)
            NavigationLink { CloudSyncView() } label: { Label("cloud.title", systemImage: "arrow.triangle.2.circlepath.icloud") }
            Button { showManage = true } label: { Label("cloud.manage", systemImage: "gearshape") }
            Text("cloud.active.pro_hint").font(.caption).foregroundStyle(.secondary)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func feature(_ icon: String, _ tint: Color, _ title: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).foregroundStyle(.white).frame(width: 34, height: 34)
                .background(tint, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}
