//
//  BackupView.swift
//  Renting
//
//  "Copia de seguridad": save all the data to a file, or restore it from one. Shown in Settings
//  and, for someone without an iCloud account, on the iCloud screen (see `Backup.swift`).
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupSection: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui
    /// A different title for the section (the iCloud screen calls it "Without iCloud").
    var header: LocalizedStringKey = "backup.title"

    /// A backup the landlord picked, waiting for the "this replaces your data" confirmation.
    private struct Pending: Equatable {
        let snapshot: Snapshot
        let fileSummary: String
        static func == (a: Pending, b: Pending) -> Bool { a.fileSummary == b.fileSummary }
    }

    @State private var exportURL: URL?
    @State private var showPicker = false
    @State private var pending: Pending?
    @State private var showConfirm = false
    /// What the last attempt ended in: an error, or the "done" message.
    @State private var notice: LocalizedStringKey?

    private var canExport: Bool { BackupService.canExport(store.data) }

    var body: some View {
        Section {
            if canExport, let exportURL {
                ShareLink(item: exportURL, preview: SharePreview(BackupService.fileName(), image: Image(systemName: "doc.text"))) {
                    Label("backup.export", systemImage: "square.and.arrow.up")
                }
            } else {
                Label("backup.export", systemImage: "square.and.arrow.up").foregroundStyle(.secondary)
            }
            Button { showPicker = true } label: { Label("backup.import", systemImage: "square.and.arrow.down") }
                .fileImporter(isPresented: $showPicker, allowedContentTypes: [.json]) { result in
                    switch result {
                    case .failure: notice = "backup.import.error"
                    case .success(let url): read(url)
                    }
                }
                .confirmationDialog("backup.import.confirm", isPresented: $showConfirm, titleVisibility: .visible, presenting: pending) { item in
                    Button("backup.import.button", role: .destructive) {
                        store.restore(from: item.snapshot)
                        notice = "backup.import.done"
                        refresh()
                    }
                } message: { item in
                    let now = BackupService.summary(of: store.data)
                    if CloudSync.shared.isEnabled {
                        Text("backup.import.message_cloud \(item.fileSummary) \(now.text)")
                    } else {
                        Text("backup.import.message \(item.fileSummary) \(now.text)")
                    }
                }
                .alert(notice ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                    Button("common.ok", role: .cancel) {}
                }
                .task { refresh(); openDebugImport() }
                .onChange(of: store.data.recordCount) { _, _ in refresh() }
                .onDisappear { clearExport() }
        } header: { Text(header) } footer: {
            Text(canExport ? "backup.export.footer" : "backup.export.disabled")
        }
    }

    // MARK: Export

    /// The file is made ahead of time because the share button needs it; it holds personal data,
    /// so it is deleted when the screen goes away.
    private func refresh() {
        clearExport()
        exportURL = canExport ? (try? BackupService.writeFile(store.data)) : nil
    }

    private func clearExport() {
        if let exportURL { try? FileManager.default.removeItem(at: exportURL) }
        exportURL = nil
    }

    // MARK: Restore

    private func read(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let snapshot = try BackupService.decode(try Data(contentsOf: url))
            pending = Pending(snapshot: snapshot, fileSummary: BackupService.summary(of: snapshot).text)
            showConfirm = true
        } catch BackupError.newerFormat {
            notice = "backup.import.newer"
        } catch BackupError.empty {
            notice = "backup.import.empty"
        } catch {
            notice = "backup.import.error"
        }
    }

    /// Development only: `-debugImport <path>` opens the confirmation for that file, as if it had been picked.
    private func openDebugImport() {
        #if DEBUG
        if let url = ui.debugImportURL { ui.debugImportURL = nil; read(url) }
        #endif
    }
}
