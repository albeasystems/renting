//
//  AlertsView.swift
//  Renting
//
//  Smart alerts (Pro): what needs attention now, grouped by urgency, with a tap that goes
//  to the right tab; the master switch for notifications; and the rules editor, where each
//  alert can be turned off, tuned and set to notify.
//

import SwiftUI

struct AlertsView: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui
    @AppStorage("isProUnlocked") private var isPro = false
    @AppStorage(AlertsManager.enabledKey) private var notificationsOn = false
    @State private var config = AlertConfig.shared
    @State private var denied = false

    var body: some View {
        let alerts = store.alerts(config: config)
        List {
            if !isPro {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("alerts.locked", systemImage: "lock.fill").font(.headline)
                        Text("alerts.teaser").font(.subheadline).foregroundStyle(.secondary)
                        Button("pro.unlock") { ui.showAlerts = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { ui.showPaywall = true } }
                            .buttonStyle(.borderedProminent).tint(Color.brand)
                    }
                    .padding(.vertical, 6)
                }
            } else {
                Section {
                    Toggle("alerts.notifications", isOn: Binding(get: { notificationsOn }, set: { setNotifications($0) }))
                    NavigationLink { AlertRulesView() } label: {
                        HStack {
                            Label("alerts.customize", systemImage: "slider.horizontal.3")
                            Spacer()
                            Text("alerts.active_rules \(AlertRuleKind.allCases.filter { config.isOn($0) }.count) \(AlertRuleKind.allCases.count)")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                } footer: { Text("alerts.notifications.footer") }
            }

            if alerts.isEmpty {
                Section { Label("alerts.none", systemImage: "checkmark.seal.fill").foregroundStyle(Color.income) }
            }
            group(alerts, .high, "alerts.group.high")
            group(alerts, .normal, "alerts.group.normal")
            group(alerts, .info, "alerts.group.info")
        }
        .navigationTitle("alerts.title")
        .alert("alerts.denied", isPresented: $denied) {
            Button("common.ok", role: .cancel) {}
        } message: { Text("alerts.denied.message") }
    }

    @ViewBuilder
    private func group(_ all: [RentAlert], _ severity: AlertSeverity, _ title: LocalizedStringKey) -> some View {
        let items = all.filter { $0.severity == severity }
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { a in
                    Button { go(a) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: a.icon).foregroundStyle(a.color).frame(width: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(a.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary).multilineTextAlignment(.leading)
                                Text(a.detail).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            if isPro { Image(systemName: "chevron.forward").font(.caption2.weight(.semibold)).foregroundStyle(.tertiary) }
                        }
                        .redacted(reason: isPro ? [] : .placeholder)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isPro)
                }
            }
        }
    }

    /// Closes the sheet and shows the tab where the alert can be solved.
    private func go(_ alert: RentAlert) {
        ui.showAlerts = false
        ui.tab = alert.kind.destination
        if alert.kind.destination == .properties { ui.homesSegment = .tenants }
    }

    private func setNotifications(_ on: Bool) {
        guard on else {
            notificationsOn = false
            Task { await AlertsManager.reschedule(store: store, isPro: isPro) }
            return
        }
        Task {
            let ok = await AlertsManager.requestAuthorization()
            notificationsOn = ok
            denied = !ok
            await AlertsManager.reschedule(store: store, isPro: isPro)
        }
    }
}

// MARK: - Rules editor

struct AlertRulesView: View {
    @Environment(RentalStore.self) private var store
    @AppStorage("isProUnlocked") private var isPro = false
    @AppStorage(AlertsManager.enabledKey) private var notificationsOn = false
    @State private var config = AlertConfig.shared
    @State private var testSent = false

    var body: some View {
        List {
            Section {
                DatePicker("rules.time", selection: Binding(get: { config.time }, set: { config.time = $0 }), displayedComponents: .hourAndMinute)
                Button {
                    Task { _ = await AlertsManager.requestAuthorization(); await AlertsManager.sendTest(); testSent = true }
                } label: { Label("rules.test", systemImage: "bell.and.waves.left.and.right") }
            } header: { Text("rules.notifications") } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("rules.time.footer")
                    if !notificationsOn { Text("rules.master_off").foregroundStyle(Color.expense) }
                    if testSent { Text("rules.test.sent").foregroundStyle(Color.income) }
                }
            }

            ForEach(AlertRuleKind.Group.allCases, id: \.self) { group in
                Section(group.title) {
                    ForEach(AlertRuleKind.allCases.filter { $0.group == group }) { kind in RuleRow(kind: kind, config: config) }
                }
            }

            Section {
                Button("rules.reset", role: .destructive) { config.reset() }.disabled(config.isDefault)
            }
        }
        .navigationTitle("rules.title")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { Task { await AlertsManager.reschedule(store: store, isPro: isPro) } }
    }
}

private struct RuleRow: View {
    let kind: AlertRuleKind
    let config: AlertConfig

    var body: some View {
        let rule = config.rule(kind)
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(get: { rule.enabled }, set: { on in config.update(kind) { $0.enabled = on } })) {
                HStack(spacing: 12) {
                    Image(systemName: kind.icon).font(.footnote).foregroundStyle(.white).frame(width: 28, height: 28)
                        .background(kind.color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text(kind.title).font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                }
            }
            Text(kind.detail).font(.caption).foregroundStyle(.secondary)
            if rule.enabled {
                if let p = kind.parameter {
                    Stepper(value: Binding(get: { rule.param }, set: { v in config.update(kind) { $0.param = v } }), in: p.range, step: p.step) {
                        HStack {
                            Text(p.title).font(.subheadline)
                            Spacer()
                            Text("\(Int(rule.param)) \(p.unit.label)").font(.subheadline.weight(.semibold)).foregroundStyle(Color.brand).monospacedDigit()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                if kind.canNotify {
                    Toggle("rules.notify", isOn: Binding(get: { rule.notify }, set: { on in config.update(kind) { $0.notify = on } }))
                        .font(.subheadline)
                } else {
                    Label("rules.in_app_only", systemImage: "iphone").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
