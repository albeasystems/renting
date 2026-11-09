//
//  SettingsView.swift
//  Renting
//

import SwiftUI

enum AppLinks {
    static let privacyPolicy = URL(string: "https://example.com/renting/privacy")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "mailto:albeasystems@gmail.com")!
    /// ⚠️ Replace `id0000000000` with the real App Store ID once the app exists.
    static let appStore = URL(string: "https://apps.apple.com/app/renting/id0000000000")!
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui
    @AppStorage("isProUnlocked") private var isPro = false
    @AppStorage("isPremiumUnlocked") private var isPremium = false
    @State private var storeManager = StoreManager.shared
    @State private var cloud = CloudSync.shared
    @State private var showCloud = false
    @State private var showPrivacyOptions = false
    @State private var versionTaps = 0
    @State private var lastVersionTap = Date.distantPast
    @State private var testUnlockMessage: LocalizedStringKey?
    @State private var confirmErase = false
    @State private var confirmDemo = false
    @State private var confirmDemoReal = false
    @AppStorage(Landlord.nameKey) private var landlordName = ""
    @AppStorage(Landlord.taxIDKey) private var landlordTaxID = ""

    var body: some View {
        @Bindable var appLanguage = AppLanguage.shared
        @Bindable var currency = AppCurrency.shared
        NavigationStack {
            Form {
                proSection
                Section {
                    TextField("receipt.landlord_name", text: $landlordName).textContentType(.name)
                    TextField("receipt.landlord_tax_id", text: $landlordTaxID)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                } header: { Text("receipt.landlord") } footer: { Text("receipt.landlord.footer") }
                Section {
                    Button { confirmDemo = true } label: { Label("settings.load_demo", systemImage: "sparkles") }
                        .disabled(cloud.isEnabled)
                    if StoreManager.testUnlockAllowed {
                        Button { confirmDemoReal = true } label: { Label("settings.load_demo_real", systemImage: "testtube.2") }
                            .disabled(cloud.isEnabled)
                    }
                    Button(role: .destructive) { confirmErase = true } label: { Label("settings.erase", systemImage: "trash") }
                } header: { Text("settings.data") } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.data.footer")
                        if cloud.isEnabled { Text("settings.data.footer_cloud") }
                        if StoreManager.testUnlockAllowed { Text("settings.load_demo_real.footer") }
                    }
                }
                BackupSection()
                Section("settings.display") {
                    Picker("settings.language", selection: $appLanguage.code) {
                        ForEach(AppLanguage.supported, id: \.self) { Text(AppLanguage.displayName($0)).tag($0) }
                    }
                    Picker("settings.currency", selection: $currency.code) {
                        ForEach(AppCurrency.supported, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("settings.ads") {
                    if isPremium { Label("settings.ads_removed", systemImage: "checkmark.seal.fill").foregroundStyle(Color.income) }
                    else { RewardedLabel().listRowInsets(EdgeInsets()).listRowBackground(Color.clear) }
                    Button("settings.restore") { Task { await storeManager.restore() } }
                }
                Section("settings.privacy") {
                    if showPrivacyOptions { Button("settings.privacy_options") { ConsentService.shared.presentPrivacyOptions() } }
                    Button("settings.tracking") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
                    Link("settings.privacy_policy", destination: AppLinks.privacyPolicy)
                    Link("settings.terms", destination: AppLinks.terms)
                }
                Section {
                    Button {
                        ReviewManager.shared.markRatedManually()
                        if var parts = URLComponents(url: AppLinks.appStore, resolvingAgainstBaseURL: false) {
                            parts.queryItems = [URLQueryItem(name: "action", value: "write-review")]
                            if let url = parts.url { openURL(url) }
                        }
                    } label: { Label("settings.rate", systemImage: "star.fill") }
                    Link("settings.support", destination: AppLinks.support)
                    LabeledContent("settings.version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                        .contentShape(Rectangle())
                        .onTapGesture { versionTapped() }
                } footer: { Text("settings.disclaimer") }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
            .navigationDestination(isPresented: $showCloud) { CloudSyncView() }
            .onAppear { if ui.settingsOpensCloud { ui.settingsOpensCloud = false; showCloud = true } }
            .task { showPrivacyOptions = ConsentService.shared.isPrivacyOptionsRequired }
            .alert(testUnlockMessage ?? "", isPresented: Binding(get: { testUnlockMessage != nil }, set: { if !$0 { testUnlockMessage = nil } })) {
                Button("common.ok", role: .cancel) {}
            }
            .confirmationDialog("settings.erase.confirm", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("settings.erase", role: .destructive) { store.eraseAll() }
            } message: { Text(cloud.isEnabled ? "settings.erase.message_cloud" : "settings.erase.message") }
            .confirmationDialog("settings.load_demo_real.confirm", isPresented: $confirmDemoReal, titleVisibility: .visible) {
                Button("settings.load_demo_real") { store.loadDemo(asReal: true) }
            } message: { Text("settings.load_demo_real.message") }
            .confirmationDialog("settings.load_demo.confirm", isPresented: $confirmDemo, titleVisibility: .visible) {
                Button("settings.load_demo") { store.loadDemo() }
            } message: { Text("settings.load_demo.message") }
        }
    }

    private var proSection: some View {
        Section {
            NavigationLink { ProPaywallView() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill").foregroundStyle(.white).frame(width: 30, height: 30)
                        .background(Color.gold, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text("pro.title")
                    Spacer()
                    if storeManager.hasCloud { Text("pro.active").font(.footnote).foregroundStyle(Color.income) }
                    else if !storeManager.cloudPriceText.isEmpty { Text("cloud.from_price \(storeManager.cloudPriceText)").font(.footnote).foregroundStyle(.secondary) }
                }
            }
            NavigationLink { CloudSyncView() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "icloud.fill").foregroundStyle(.white).frame(width: 30, height: 30)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text("cloud.title")
                    Spacer()
                    Text(cloud.state.title).font(.footnote).foregroundStyle(cloud.state.color).lineLimit(1)
                }
            }
            NavigationLink { AlertsView() } label: { proRow("bell.badge.fill", .expense, "alerts.title") }
            Button { ui.showSettings = false; ui.tab = .fiscal } label: { proRow("doc.richtext.fill", .brand, "reports.title") }
                .foregroundStyle(.primary)
        } footer: { if !isPro { Text("pro.footer") } }
    }

    private func proRow(_ icon: String, _ tint: Color, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.white).frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(title)
            Spacer()
            if !isPro { Image(systemName: "lock.fill").font(.footnote).foregroundStyle(.secondary) }
        }
    }

    /// Ten quick taps on the version row switch the test unlock (the subscription) on or off
    /// (development and TestFlight builds only). The count starts over after a pause.
    private func versionTapped() {
        guard StoreManager.testUnlockAllowed else { return }
        let now = Date()
        if now.timeIntervalSince(lastVersionTap) > 2 { versionTaps = 0 }
        lastVersionTap = now
        versionTaps += 1
        guard versionTaps >= 10 else { return }
        versionTaps = 0
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        Task {
            let on = await storeManager.toggleTestUnlock()
            testUnlockMessage = on ? "settings.test_unlock.cloud" : "settings.test_unlock.off"
        }
    }
}
