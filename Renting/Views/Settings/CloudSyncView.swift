//
//  CloudSyncView.swift
//  Renting
//
//  Settings › iCloud: whether the data is being kept in sync, with the switch, a "sync now"
//  button, what is and is not synced, and a way to delete the copy in iCloud. The switch is
//  part of the "Renting Cloud" subscription; without it the screen explains and links to it.
//

import SwiftUI

extension CloudSync.State {
    var icon: String {
        switch self {
        case .upToDate: "checkmark.icloud.fill"
        case .syncing, .starting: "arrow.triangle.2.circlepath.icloud.fill"
        case .off, .needsSubscription: "icloud.slash"
        case .noAccount, .restricted, .accountChanged, .remoteDeleted, .error, .quota, .needsUpdate, .demoData: "exclamationmark.icloud.fill"
        }
    }

    var color: Color {
        switch self {
        case .upToDate: .income
        case .syncing, .starting: .brand
        case .off, .needsSubscription: .secondary
        default: .expense
        }
    }

    /// The one-line status shown in Settings and on the iCloud screen.
    var title: String {
        switch self {
        case .off: L("cloud.state.off")
        case .needsSubscription: L("cloud.state.needs_subscription")
        case .demoData: L("cloud.state.demo")
        case .noAccount: L("cloud.state.no_account")
        case .restricted: L("cloud.state.restricted")
        case .accountChanged: L("cloud.state.account_changed")
        case .remoteDeleted: L("cloud.state.remote_deleted")
        case .starting: L("cloud.state.starting")
        case .syncing: L("cloud.state.syncing")
        case .upToDate: L("cloud.state.up_to_date")
        case .quota: L("cloud.state.quota")
        case .needsUpdate: L("cloud.state.needs_update")
        case .error(let message): L("cloud.state.error", message)
        }
    }

    /// What to do about it, when the state is a problem.
    var advice: LocalizedStringKey? {
        switch self {
        case .noAccount: "cloud.advice.no_account"
        case .restricted: "cloud.advice.restricted"
        case .accountChanged: "cloud.advice.account_changed"
        case .remoteDeleted: "cloud.advice.remote_deleted"
        case .quota: "cloud.advice.quota"
        case .needsUpdate: "cloud.advice.needs_update"
        case .demoData: "cloud.advice.demo"
        default: nil
        }
    }
}

struct CloudSyncView: View {
    @Environment(RentalStore.self) private var store
    @State private var sync = CloudSync.shared
    @State private var plan = StoreManager.shared
    @State private var confirmEnable = false
    @State private var confirmDelete = false
    @State private var working = false
    @State private var showPlan = false
    @State private var diagnostics = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: sync.state.icon).font(.title2).foregroundStyle(sync.state.color).frame(width: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sync.state.title).font(.subheadline.weight(.semibold))
                        if let last = sync.lastSync, sync.isActive {
                            Text("cloud.last \(last.formatted(.relative(presentation: .named).locale(AppLanguage.shared.locale)))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if sync.pendingCount > 0 && sync.isActive {
                            Text("cloud.pending \(sync.pendingCount)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if let advice = sync.state.advice { Text(advice).font(.footnote).foregroundStyle(.secondary) }
            }

            // No iCloud account (or iCloud restricted): the data can still be kept safe in a file.
            if sync.state == .noAccount || sync.state == .restricted { BackupSection(header: "backup.no_icloud") }

            if !plan.hasCloud {
                Section {
                    NavigationLink { ProPaywallView() } label: { Label("cloud.see_plan", systemImage: "icloud.and.arrow.up.fill") }
                } footer: { Text("cloud.needs_plan.footer") }
            }

            Section {
                // Without the subscription the switch still answers: it opens the plan.
                Toggle("cloud.toggle", isOn: Binding(
                    get: { sync.isEnabled },
                    set: { on in
                        if !on { sync.isEnabled = false }
                        else if plan.hasCloud { confirmEnable = true }
                        else { showPlan = true }
                    }))
                if sync.isActive {
                    Button {
                        Task { working = true; await sync.syncNow(); working = false }
                    } label: {
                        HStack { Label("cloud.sync_now", systemImage: "arrow.clockwise"); Spacer(); if working { ProgressView() } }
                    }
                    .disabled(working)
                }
            } footer: { Text("cloud.toggle.footer") }

            Section("cloud.what") {
                Label { Text("cloud.what.synced") } icon: { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.income) }
                    .font(.subheadline)
                Label("cloud.what.local", systemImage: "iphone").foregroundStyle(.secondary).font(.footnote)
            }

            Section {
                Label("cloud.privacy", systemImage: "lock.icloud.fill").font(.footnote)
            } header: { Text("cloud.privacy.title") }

            if plan.hasCloud || sync.isEnabled || sync.lastSync != nil {
                Section {
                    Button("cloud.delete", role: .destructive) { confirmDelete = true }.disabled(working)
                } footer: { Text("cloud.delete.footer") }
            }

            // Development and TestFlight builds only: what is needed to find out why sync is not running.
            if StoreManager.testUnlockAllowed {
                Section {
                    Text(verbatim: diagnostics).font(.caption.monospaced()).textSelection(.enabled)
                    Button(action: { Task { diagnostics = await sync.diagnostics() } }) { Text(verbatim: "Refresh") }
                } header: { Text(verbatim: "Diagnostics") }
            }
        }
        .navigationTitle("cloud.title")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPlan) { ProSheet { ProPaywallView() } }
        .confirmationDialog("cloud.enable.confirm", isPresented: $confirmEnable, titleVisibility: .visible) {
            Button("cloud.enable") { sync.isEnabled = true }
        } message: { Text("cloud.enable.message") }
        .confirmationDialog("cloud.delete.confirm", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("cloud.delete", role: .destructive) { Task { working = true; await sync.deleteCloudData(); working = false } }
        } message: { Text("cloud.delete.message") }
        .task {
            await sync.evaluate()
            if StoreManager.testUnlockAllowed { diagnostics = await sync.diagnostics() }
        }
        .onChange(of: sync.state) { _, _ in
            if StoreManager.testUnlockAllowed { Task { diagnostics = await sync.diagnostics() } }
        }
    }
}
