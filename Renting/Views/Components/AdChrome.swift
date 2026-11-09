//
//  AdChrome.swift
//  Renting
//
//  The UI around ads: the fixed banner slot and the rewarded offer. Interstitials are
//  only requested at navigation breakpoints (leaving a detail screen, switching tab)
//  through `AdsManager.registerKeyAction()` — never on a timer.
//

import SwiftUI

extension View {
    /// Pins the banner slot above the tab bar. The slot has a fixed height from the
    /// first frame, so loading the ad never moves the content. With `showsRewarded`
    /// the "watch a video, get an hour without ads" label rides directly above it.
    func bannerInset(_ placement: AdConfig.Placement, showsRewarded: Bool = false) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if showsRewarded { RewardedLabel() }
                FreeBanner(placement: placement)
            }
        }
    }

    /// Counts a navigation breakpoint towards the next interstitial.
    func countsAsBreakpoint() -> some View {
        onDisappear { registerBreakpoint() }
    }
}

/// In the order of the tab bar.
enum AppTab: Hashable, CaseIterable { case dashboard, properties, collections, expenses, fiscal }

/// The two lists of the Homes tab.
enum HomesSegment: Hashable { case homes, tenants }

/// The screens one can drill into from the Homes tab. They are values (not views) so that the
/// stack can be emptied from outside: tapping the tab goes back to its first screen.
enum HomesRoute: Hashable {
    case property(UUID), unit(UUID), tenant(UUID), expenses(UUID)
}

/// A tap on a month that already has a payment asks before removing it.
struct UnmarkRequest: Identifiable, Equatable {
    let tenant: Tenant
    let month: MonthKey
    var id: String { "\(tenant.id)\(month.id)" }
}

/// App-wide presentation state.
@MainActor
@Observable
final class AppUI {
    var tab: AppTab = .dashboard
    var homesSegment: HomesSegment = .homes
    var homesPath: [HomesRoute] = []
    /// A "get started" button asked the Homes tab to open the sheet for this step.
    var pendingSetup: SetupStep?
    /// A payment the landlord tapped to remove: the confirmation is shown once, at the root.
    var unmark: UnmarkRequest?
    #if DEBUG
    /// Development only: a backup file the Settings screen opens as if it had been picked (`-debugImport <path>`).
    var debugImportURL: URL?
    #endif

    /// Goes to the Homes tab and opens the sheet for the next step of the set-up.
    func startSetup(_ step: SetupStep) {
        homesPath = []
        homesSegment = step == .addTenant ? .tenants : .homes
        tab = .properties
        pendingSetup = step
    }

    /// Ticks a month; a month that already has a payment (and may carry a custom amount and date)
    /// is only removed after the landlord confirms.
    func tapPayment(_ tenant: Tenant, month: MonthKey, store: RentalStore) {
        if store.payment(of: tenant.id, in: month) != nil { unmark = UnmarkRequest(tenant: tenant, month: month) }
        else { store.togglePayment(tenant, month: month) }
    }

    /// A tab of the tab bar was tapped (also the one already open): it shows its first screen.
    func tabTapped(_ tab: AppTab) {
        if tab == .properties, !homesPath.isEmpty { withAnimation { homesPath = [] } }
    }
    var showSettings = false
    /// Debug: opens Settings straight on the iCloud screen.
    var settingsOpensCloud = false
    var showAlerts = false
    var showPaywall = false
}

/// A navigation breakpoint. The rating always gets the first chance at the moment,
/// so it is registered BEFORE the interstitial counter.
@MainActor
func registerBreakpoint() {
    ReviewManager.shared.registerKeyAction()
    AdsManager.shared.registerKeyAction()
}

/// Gear button in the navigation bar: always on the left; the other controls of a tab go on the right.
struct SettingsButton: ViewModifier {
    @Environment(AppUI.self) private var ui
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { ui.showSettings = true } label: { Image(systemName: "gearshape.fill") }
                    .accessibilityLabel(Text("settings.title"))
            }
        }
    }
}

extension View {
    func withSettingsButton() -> some View { modifier(SettingsButton()) }
}

/// Compact rewarded entry point pinned above the banner: watch one video, get an hour
/// without ads (which also unlocks the fiscal PDF for that hour). Pro owners never see it.
struct RewardedLabel: View {
    @ObservedObject private var ads = AdsManager.shared
    @AppStorage("isPremiumUnlocked") private var isPremium = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var showUnavailable = false
    @State private var isFetching = false

    var body: some View {
        Group {
            if isPremium {
                EmptyView()
            } else if let until = ads.adFreeUntil, until > Date() {
                activeCard(until: until)
            } else {
                // Always offered, even with nothing preloaded: fill is unreliable and an
                // entry point shown only when an ad happens to be cached is never seen.
                offerButton
            }
        }
        .background(Color(.systemGroupedBackground))
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { ads.refreshAdFreeState() }
        }
        .alert("rewarded.unavailable_title", isPresented: $showUnavailable) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("rewarded.unavailable_message")
        }
    }

    private var offerButton: some View {
        Button {
            guard !isFetching else { return }
            isFetching = true
            Task {
                let shown = await ads.showRewardedFetchingIfNeeded()
                isFetching = false
                if !shown { showUnavailable = true }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.rectangle.fill")
                Text("rewarded.watch").fontWeight(.semibold).lineLimit(2).minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                if isFetching { ProgressView().controlSize(.small) } else { Image(systemName: "chevron.forward").font(.caption) }
            }
            .font(.footnote)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.brand, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 4)
    }

    private func activeCard(until: Date) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.checkmark")
            Text("rewarded.active").fontWeight(.semibold)
            Spacer(minLength: 0)
            Text(until, style: .relative).monospacedDigit()
        }
        .font(.footnote)
        .foregroundStyle(Color.white)
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color.income, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16).padding(.bottom, 4)
    }
}
