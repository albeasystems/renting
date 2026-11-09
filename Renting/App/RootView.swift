//
//  RootView.swift
//  Renting
//
//  Root container: onboarding once, then the tabs. Owns the launch sequence that has
//  to happen in this exact order before any ad is requested:
//    1. App Tracking Transparency prompt
//    2. EU/UK consent form (Google UMP)
//    3. LevelPlay SDK initialisation
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppUI.self) private var ui
    @Environment(RentalStore.self) private var store
    @Environment(AppLanguage.self) private var language
    @Environment(AppCurrency.self) private var currency
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isProUnlocked") private var isPro = false
    /// The notice about an unreadable data file is shown once the interface is up: SwiftUI does not
    /// present an alert that is already "on" in the very first render.
    @State private var showRecovery = false
    @State private var showSaveError = false

    /// The welcome screen has been seen and there is at least one home.
    private var readyForPrompts: Bool { hasSeenOnboarding && !store.isEmpty }

    var body: some View {
        @Bindable var ui = ui
        Group {
            if hasSeenOnboarding { tabs } else { OnboardingView() }
        }
        .alert("data.recovered.title", isPresented: $showRecovery) {
            Button("common.ok", role: .cancel) { store.dismissRecoveryNotice() }
        } message: { Text("data.recovered.message \(store.recoveredBackup ?? "")") }
        .alert("data.save_failed.title", isPresented: $showSaveError) {
            Button("common.ok", role: .cancel) {}
        } message: { Text("data.save_failed.message \(store.saveError ?? "")") }
        .onChange(of: store.saveError) { _, error in showSaveError = error != nil }
        // The widget opens the Collections tab with renting://collections.
        .onOpenURL { url in
            guard url.scheme == "renting", url.host == "collections" else { return }
            ui.showSettings = false; ui.showAlerts = false; ui.showPaywall = false
            ui.tab = .collections
        }
        // The widget shows text and amounts in the app's language and currency.
        .onChange(of: language.code) { _, _ in WidgetBridge.refresh() }
        .onChange(of: currency.code) { _, _ in WidgetBridge.refresh() }
        .sheet(isPresented: $ui.showSettings) { SettingsView() }
        .sheet(isPresented: $ui.showAlerts) { ProSheet { AlertsView() } }
        .sheet(isPresented: $ui.showPaywall) { ProSheet { ProPaywallView() } }
        .task {
            if store.recoveredBackup != nil {
                try? await Task.sleep(nanoseconds: 700_000_000)
                showRecovery = true
            }
            #if DEBUG
            applyDebugLaunchArguments()
            #endif
            // Cold launch: nothing here asks the user for anything.
            ReviewManager.shared.noteForeground()
            WidgetBridge.refresh()
            StoreManager.shared.start()
            await AlertsManager.reschedule(store: store, isPro: isPro)
            await CloudSync.shared.evaluate()
        }
        // The tracking prompt, the consent form and the ads come after the welcome screen and once
        // the user has something in the app (a home): asking before that put three dialogs in
        // front of someone who had not yet seen what the app does. The order is the one the ads
        // SDK needs: ATT, then the GDPR/CMP flow, then the SDK itself.
        .task(id: readyForPrompts) {
            guard readyForPrompts else { return }
            await AppTrackingService.shared.requestTrackingIfNeeded()
            await ConsentService.shared.resolve()
            AdsManager.shared.start()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                WidgetBridge.refresh()
                ReviewManager.shared.noteBackground()
                Task { await AlertsManager.reschedule(store: store, isPro: isPro) }
            case .active:
                ReviewManager.shared.noteForeground()
                CloudSync.shared.appBecameActive()
            default:
                break
            }
        }
    }

    #if DEBUG
    /// Development only (compiled out of release): `-debugPro 1`, `-debugNoPro 1`,
    /// `-debugOpen reports|alerts|settings|paywall|cloud`, `-debugTab …`, `-debugDemo 1`,
    /// `-debugDemoAsReal 1` (sample portfolio as real data, to test iCloud sync).
    private func applyDebugLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-debugDemo") { hasSeenOnboarding = true; if store.isEmpty { store.loadDemo() } }
        if args.contains("-debugDemoAsReal") { hasSeenOnboarding = true; if store.isEmpty { store.loadDemo(asReal: true) } }
        // There is a single paid plan: -debugPro and -debugCloud both switch the subscription on.
        if args.contains("-debugPro") || args.contains("-debugCloud") {
            UserDefaults.standard.set(true, forKey: StoreManager.testUnlockKey)
            UserDefaults.standard.set(true, forKey: StoreManager.cloudKey)
            UserDefaults.standard.set(true, forKey: StoreManager.proKey)
            UserDefaults.standard.set(true, forKey: StoreManager.adFreeKey)
        }
        if args.contains("-debugNoPro") {
            UserDefaults.standard.set(false, forKey: StoreManager.cloudKey)
            UserDefaults.standard.set(false, forKey: StoreManager.testUnlockKey)
            UserDefaults.standard.set(false, forKey: StoreManager.proKey)
            UserDefaults.standard.set(false, forKey: StoreManager.adFreeKey)
        }
        if args.contains("-debugReviewReset") { ReviewManager.shared.debugReset() }
        if args.contains("-debugSyncTest") { SyncSelfTest.run() }
        if args.contains("-debugAudit") { AuditTest.run() }
        if args.contains("-debugWriteBackup"), let url = try? BackupService.writeFile(store.data) {
            let target = FileManager.default.temporaryDirectory.appendingPathComponent("debug-backup.json")
            try? FileManager.default.removeItem(at: target)
            try? FileManager.default.moveItem(at: url, to: target)
        }
        if let i = args.firstIndex(of: "-debugImport"), i + 1 < args.count {
            ui.debugImportURL = URL(fileURLWithPath: args[i + 1])
            ui.showSettings = true
        }
        if let i = args.firstIndex(of: "-debugOpen"), i + 1 < args.count {
            switch args[i + 1] {
            case "reports": ui.tab = .fiscal
            case "alerts": ui.showAlerts = true
            case "settings": ui.showSettings = true
            case "paywall": ui.showPaywall = true
            case "cloud": ui.showSettings = true; ui.settingsOpensCloud = true
            default: break
            }
        }
        if let i = args.firstIndex(of: "-debugTab"), i + 1 < args.count {
            switch args[i + 1] {
            case "properties": ui.tab = .properties
            case "collections": ui.tab = .collections
            case "expenses": ui.tab = .expenses
            case "tenants": ui.tab = .properties; ui.homesSegment = .tenants
            case "fiscal": ui.tab = .fiscal
            default: break
            }
        }
    }
    #endif

    private var tabs: some View {
        @Bindable var ui = ui
        return TabView(selection: $ui.tab) {
            DashboardView()
                .tabItem { Label("tab.dashboard", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.dashboard)
            PropertiesView()
                .tabItem { Label("tab.properties", systemImage: "building.2.fill") }
                .tag(AppTab.properties)
            CollectionsView()
                .tabItem { Label("tab.collections", systemImage: "checkmark.circle.fill") }
                .tag(AppTab.collections)
            ExpensesView()
                .tabItem { Label("tab.expenses", systemImage: "creditcard.fill") }
                .tag(AppTab.expenses)
            NavigationStack {
                FiscalView().withSettingsButton().bannerInset(.fiscal)
            }
            .tabItem { Label("tab.fiscal", systemImage: "building.columns.fill") }
            .tag(AppTab.fiscal)
        }
        .tint(Color.brand)
        // Removing a payment (with the amount and date typed for it) is asked about once, wherever it was tapped.
        .confirmationDialog("coll.unmark.confirm", isPresented: Binding(get: { ui.unmark != nil }, set: { if !$0 { ui.unmark = nil } }),
                            titleVisibility: .visible, presenting: ui.unmark) { request in
            Button("coll.unmark", role: .destructive) { store.removePayment(request.tenant, month: request.month) }
        } message: { request in
            Text("coll.unmark.message \(request.tenant.name) \(request.month.title())")
        }
        // Switching tab is a natural breakpoint: it counts towards the next interstitial
        // but never shows one on its own timer.
        .onChange(of: ui.tab) { _, _ in registerBreakpoint() }
        // Tapping a tab takes it back to its first screen.
        .task {
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: 300_000_000)
                TabTapObserver.shared.install { index in
                    if AppTab.allCases.indices.contains(index) { ui.tabTapped(AppTab.allCases[index]) }
                }
            }
        }
    }
}

/// Wraps a screen presented as a sheet in its own navigation stack.
struct ProSheet<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content().toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
        }
    }
}
