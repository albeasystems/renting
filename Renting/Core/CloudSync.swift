//
//  CloudSync.swift
//  Renting
//
//  Syncs the data between the user's devices through the PRIVATE CloudKit database of their
//  own iCloud account: the data goes from the user's devices to the user's iCloud and back,
//  never through a server of ours, and we cannot read it. It uses `CKSyncEngine`, which does
//  the fetching, batching, retrying and push notifications; this file tells it what changed
//  (`SyncModel.swift` cuts the data into records) and applies what comes back.
//
//  Sync runs only when: the user switched it on, the "Renting Cloud" subscription is active,
//  the data is not the sample data and an iCloud account is available. Otherwise it stops and
//  nothing is lost: the data stays on the device and in iCloud, and an edit made meanwhile
//  is uploaded when sync resumes (`reconcile`).
//
//  What is kept besides the data: a `base` copy of the data as it was when it last matched
//  the cloud (to know what changed while sync was off), the CloudKit change tags of each
//  record, the time of each record's last edit (for the last-writer-wins rule) and the
//  engine's own state.
//

import CloudKit
import Foundation
import Observation

@MainActor
@Observable
final class CloudSync: CKSyncEngineDelegate {
    static let shared = CloudSync()

    nonisolated static let containerID = "iCloud.com.albeasystems.renting"
    nonisolated static let zoneID = CKRecordZone.ID(zoneName: "Renting", ownerName: CKCurrentUserDefaultName)
    nonisolated static let recordType = "Item"
    /// Version of the record layout. A device that finds a newer one asks for an app update
    /// instead of misreading it.
    nonisolated static let schema = 1
    private static let enabledKey = "cloud_sync_enabled"

    enum State: Equatable {
        case off
        case needsSubscription
        case demoData
        case noAccount
        case restricted
        /// The iCloud account is not the one the data was synced with: sync was switched off.
        case accountChanged
        /// Another device removed the cloud copy: sync was switched off here, local data untouched.
        case remoteDeleted
        case starting
        case syncing
        case upToDate
        case quota
        case needsUpdate
        case error(String)
    }

    private(set) var state: State = .off
    private(set) var lastSync: Date?
    private(set) var pendingCount = 0
    private var enabled = UserDefaults.standard.bool(forKey: CloudSync.enabledKey)

    /// The user's switch. Turning it on or off starts or stops the engine.
    var isEnabled: Bool {
        get { enabled }
        set {
            enabled = newValue
            UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
            Task { await evaluate() }
        }
    }

    /// The engine is running (the data is being kept in sync).
    var isActive: Bool { engine != nil }

    // MARK: Persistence

    private struct SyncFile: Codable {
        var engineState: Data?
        /// Archived CloudKit system fields (change tags) by record name.
        var fields: [String: Data] = [:]
        /// Time of the last edit of each record, by record name.
        var modified: [String: Date] = [:]
        /// The data as it was when it last matched the cloud.
        var base = Snapshot()
        var zoneReady = false
        var lastSync: Date?
        /// The iCloud user the data was synced with.
        var userID: String?
    }

    @ObservationIgnored private var file = SyncFile()
    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var engine: CKSyncEngine?
    @ObservationIgnored private var cloudContainer: CKContainer?
    @ObservationIgnored private var lastForegroundFetch = Date.distantPast

    private var store: RentalStore { .shared }
    private var container: CKContainer {
        if let c = cloudContainer { return c }
        let c = CKContainer(identifier: Self.containerID)
        cloudContainer = c
        return c
    }

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = base.appendingPathComponent("renting-sync.json")
        if let raw = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode(SyncFile.self, from: raw) {
            file = saved
            lastSync = saved.lastSync
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled, let self else { return }
            if let raw = try? JSONEncoder().encode(self.file) { try? raw.write(to: self.fileURL, options: .atomic) }
        }
    }

    private func saveNow() {
        saveTask?.cancel()
        if let raw = try? JSONEncoder().encode(file) { try? raw.write(to: fileURL, options: .atomic) }
    }

    // MARK: Switching on and off

    /// Called when the subscription starts or ends.
    func entitlementsChanged() { Task { await evaluate() } }

    /// Called when the app comes to the front: re-checks the account and pulls fresh changes.
    func appBecameActive() {
        Task {
            await evaluate()
            guard let engine, Date().timeIntervalSince(lastForegroundFetch) > 20 else { return }
            lastForegroundFetch = Date()
            try? await engine.fetchChanges()
        }
    }

    /// Decides whether sync can run now and starts or stops the engine to match.
    func evaluate() async {
        guard enabled else { stop(); state = .off; return }
        guard StoreManager.shared.hasCloud else { stop(); state = .needsSubscription; return }
        guard !store.isDemo else { stop(); state = .demoData; return }
        let status: CKAccountStatus
        do { status = try await container.accountStatus() } catch {
            stop(); state = .error(error.localizedDescription); return
        }
        switch status {
        case .available: await start()
        case .noAccount: stop(); state = .noAccount
        case .restricted: stop(); state = .restricted
        case .couldNotDetermine, .temporarilyUnavailable: stop(); state = .error(L("cloud.err.unavailable"))
        @unknown default: stop(); state = .error(L("cloud.err.unavailable"))
        }
    }

    private func start() async {
        guard engine == nil else { return }
        // The data belongs to one iCloud account: if it changed, ask before mixing the two.
        if let userID = try? await container.userRecordID().recordName {
            if let saved = file.userID, saved != userID {
                file = SyncFile()
                file.userID = userID
                saveNow()
                enabled = false
                UserDefaults.standard.set(false, forKey: Self.enabledKey)
                state = .accountChanged
                return
            }
            file.userID = userID
        }
        state = .starting
        let serialization = file.engineState.flatMap { try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: $0) }
        var config = CKSyncEngine.Configuration(database: container.privateCloudDatabase, stateSerialization: serialization, delegate: self)
        config.automaticallySync = true
        let engine = CKSyncEngine(config)
        self.engine = engine
        if !file.zoneReady { engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))]) }
        reconcile(engine)
        store.syncObserver = { [weak self] old, new in self?.localChanged(old: old, new: new) }
        scheduleSave()
    }

    private func stop() {
        guard engine != nil else { return }
        engine = nil
        store.syncObserver = nil
        pendingCount = 0
        saveNow()
    }

    // MARK: What to upload

    /// Marks for upload whatever differs from `base`: edits made while sync was off, or all the
    /// data the first time. Also marks for deletion what was removed meanwhile.
    private func reconcile(_ engine: CKSyncEngine) {
        // A device with no data of its own (new, reinstalled or just erased while sync was off)
        // must not delete what the cloud holds: it downloads it instead. Wiping the cloud is
        // done on purpose with "Delete my data from iCloud".
        let d = store.data
        if d.properties.isEmpty && d.units.isEmpty && d.tenants.isEmpty && d.expenses.isEmpty && d.payments.isEmpty {
            file.base = Snapshot()
            file.modified = [:]
        }
        let current = store.data.syncEntities
        let (saved, deleted) = Snapshot.diff(file.base.syncEntities, current)
        let now = Date()
        for name in saved { file.modified[name] = file.modified[name].map { max($0, now) } ?? now }
        queue(saved: saved, deleted: deleted, on: engine)
    }

    /// The landlord changed something (the store calls this on every edit).
    private func localChanged(old: Snapshot, new: Snapshot) {
        guard let engine, !old.isDemo, !new.isDemo else { return }
        let (saved, deleted) = Snapshot.syncDiff(from: old, to: new)
        guard !saved.isEmpty || !deleted.isEmpty else { return }
        let now = Date()
        for name in saved { file.modified[name] = now }
        queue(saved: saved, deleted: deleted, on: engine)
        scheduleSave()
    }

    private func queue(saved: [String], deleted: [String], on engine: CKSyncEngine) {
        func id(_ name: String) -> CKRecord.ID { CKRecord.ID(recordName: name, zoneID: Self.zoneID) }
        var changes: [CKSyncEngine.PendingRecordZoneChange] = saved.map { .saveRecord(id($0)) }
        changes += deleted.map { .deleteRecord(id($0)) }
        guard !changes.isEmpty else { return }
        engine.state.add(pendingRecordZoneChanges: changes)
        pendingCount = engine.state.pendingRecordZoneChanges.count
        if state == .upToDate { state = .syncing }
    }

    /// Uploads and downloads right now.
    func syncNow() async {
        guard let engine else { return }
        state = .syncing
        do {
            try await engine.fetchChanges()
            try await engine.sendChanges()
        } catch {
            handle(error)
        }
    }

    // MARK: Removing the cloud copy

    /// Deletes the copy in iCloud (the data on this device is kept) and switches sync off.
    func deleteCloudData() async {
        stop()
        do {
            try await container.privateCloudDatabase.deleteRecordZone(withID: Self.zoneID)
        } catch let error as CKError where error.code == .zoneNotFound {
            // already gone
        } catch {
            state = .error(error.localizedDescription)
            return
        }
        file = SyncFile()
        file.userID = nil
        saveNow()
        enabled = false
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
        state = .off
        lastSync = nil
    }

    // MARK: CKSyncEngineDelegate

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let e):
            file.engineState = try? JSONEncoder().encode(e.stateSerialization)
            scheduleSave()
        case .accountChange(let e):
            handleAccountChange(e.changeType)
        case .fetchedDatabaseChanges(let e):
            handleDatabaseChanges(e)
        case .fetchedRecordZoneChanges(let e):
            applyFetched(e.modifications.map(\.record), deleted: e.deletions.map(\.recordID), engine: syncEngine)
        case .sentRecordZoneChanges(let e):
            handleSent(e, engine: syncEngine)
        case .sentDatabaseChanges(let e):
            if e.savedZones.contains(where: { $0.zoneID == Self.zoneID }) { file.zoneReady = true; scheduleSave() }
            if let failure = e.failedZoneSaves.first { handle(failure.error) }
        case .willFetchChanges, .willSendChanges:
            if state == .starting || state == .upToDate { state = .syncing }
        case .didFetchChanges:
            store.pruneOrphansFromCloud()
            finished(syncEngine)
        case .didSendChanges:
            finished(syncEngine)
        default:
            break
        }
    }

    func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext, syncEngine: CKSyncEngine) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let scope = context.options.scope
        let changes = syncEngine.state.pendingRecordZoneChanges.filter { scope.contains($0) }
        guard !changes.isEmpty else { return nil }
        let entities = store.data.syncEntities
        var records: [CKRecord.ID: CKRecord] = [:]
        var gone: [CKSyncEngine.PendingRecordZoneChange] = []
        for change in changes {
            guard case .saveRecord(let id) = change else { continue }
            if let entity = entities[id.recordName], let record = makeRecord(entity, id: id) { records[id] = record } else { gone.append(change) }
        }
        // Saved but no longer there (deleted again before it was uploaded): nothing to send.
        if !gone.isEmpty { syncEngine.state.remove(pendingRecordZoneChanges: gone) }
        let sendable = changes.filter { !gone.contains($0) }
        guard !sendable.isEmpty else { return nil }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: sendable) { records[$0] }
    }

    // MARK: Events

    private func finished(_ engine: CKSyncEngine) {
        pendingCount = engine.state.pendingRecordZoneChanges.count
        guard state == .syncing || state == .starting else { return }
        state = .upToDate
        lastSync = Date()
        file.lastSync = lastSync
        scheduleSave()
    }

    private func handleAccountChange(_ change: CKSyncEngine.Event.AccountChange.ChangeType) {
        switch change {
        case .signIn:
            break
        case .signOut:
            stop()
            state = .noAccount
        case .switchAccounts:
            stop()
            file = SyncFile()
            saveNow()
            enabled = false
            UserDefaults.standard.set(false, forKey: Self.enabledKey)
            state = .accountChanged
        @unknown default:
            break
        }
    }

    private func handleDatabaseChanges(_ e: CKSyncEngine.Event.FetchedDatabaseChanges) {
        for deletion in e.deletions where deletion.zoneID == Self.zoneID {
            stop()
            file = SyncFile()
            saveNow()
            if deletion.reason == .encryptedDataReset {
                // The keys were reset: upload everything again.
                Task { await evaluate() }
            } else {
                enabled = false
                UserDefaults.standard.set(false, forKey: Self.enabledKey)
                state = .remoteDeleted
            }
        }
    }

    /// Records that arrived from iCloud: the newer edit wins; deletions are applied.
    private func applyFetched(_ records: [CKRecord], deleted: [CKRecord.ID], engine: CKSyncEngine) {
        var upserts: [SyncEntity] = []
        var names: [String] = []
        var keepLocal: [String] = []
        for record in records {
            let name = record.recordID.recordName
            file.fields[name] = Self.archive(record)
            guard (record["schema"] as? Int ?? 1) <= Self.schema else { state = .needsUpdate; continue }
            guard let (kind, _) = SyncEntity.parse(name), let payload = record["payload"] as? Data,
                  let entity = try? SyncEntity.decode(kind: kind, from: payload) else { continue }
            let remoteDate = record["modifiedAt"] as? Date ?? .distantPast
            if SyncMerge.remoteWins(remote: remoteDate, local: file.modified[name]) {
                upserts.append(entity)
                file.modified[name] = remoteDate
            } else {
                keepLocal.append(name)
            }
        }
        for id in deleted {
            let name = id.recordName
            names.append(name)
            file.fields[name] = nil
            file.modified[name] = nil
        }
        // Local edits that are newer must still go up (with the new change tag).
        if !keepLocal.isEmpty { queue(saved: keepLocal, deleted: [], on: engine) }
        // A deletion beats a pending upload of the same record.
        if !names.isEmpty {
            engine.state.remove(pendingRecordZoneChanges: names.map { .saveRecord(CKRecord.ID(recordName: $0, zoneID: Self.zoneID)) })
        }
        guard !upserts.isEmpty || !names.isEmpty else { return }
        file.base.apply(upserts, deleting: names)
        store.applyFromCloud(upserts, deleting: names)
        scheduleSave()
    }

    private func handleSent(_ e: CKSyncEngine.Event.SentRecordZoneChanges, engine: CKSyncEngine) {
        for record in e.savedRecords {
            let name = record.recordID.recordName
            file.fields[name] = Self.archive(record)
            if let (kind, _) = SyncEntity.parse(name), let payload = record["payload"] as? Data,
               let entity = try? SyncEntity.decode(kind: kind, from: payload) {
                file.base.apply([entity], deleting: [])
            }
        }
        for id in e.deletedRecordIDs {
            let name = id.recordName
            file.fields[name] = nil
            file.modified[name] = nil
            file.base.apply([], deleting: [name])
        }
        for failure in e.failedRecordSaves {
            let id = failure.record.recordID
            let name = id.recordName
            switch failure.error.code {
            case .serverRecordChanged:
                // Someone else saved it first: keep the newer edit.
                guard let server = failure.error.serverRecord else { break }
                let remoteDate = server["modifiedAt"] as? Date ?? .distantPast
                if SyncMerge.remoteWins(remote: remoteDate, local: file.modified[name]) {
                    engine.state.remove(pendingRecordZoneChanges: [.saveRecord(id)])
                    applyFetched([server], deleted: [], engine: engine)
                } else {
                    file.fields[name] = Self.archive(server)
                    engine.state.add(pendingRecordZoneChanges: [.saveRecord(id)])
                }
            case .zoneNotFound:
                file.zoneReady = false
                engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
                engine.state.add(pendingRecordZoneChanges: [.saveRecord(id)])
            case .unknownItem:
                file.fields[name] = nil
                engine.state.add(pendingRecordZoneChanges: [.saveRecord(id)])
            case .quotaExceeded:
                state = .quota
            case .networkFailure, .networkUnavailable, .serviceUnavailable, .zoneBusy, .requestRateLimited, .notAuthenticated, .operationCancelled:
                break   // the engine retries
            default:
                handle(failure.error)
            }
        }
        pendingCount = engine.state.pendingRecordZoneChanges.count
        scheduleSave()
    }

    private func handle(_ error: Error) {
        guard let ck = error as? CKError else { state = .error(error.localizedDescription); return }
        switch ck.code {
        case .quotaExceeded: state = .quota
        case .networkFailure, .networkUnavailable, .notAuthenticated: state = .error(L("cloud.err.network"))
        default: state = .error("\(ck.localizedDescription) (CloudKit \(ck.code.rawValue))")
        }
    }

    /// A plain-text summary of what sync depends on, for development and TestFlight builds.
    func diagnostics() async -> String {
        var lines = ["container: \(Self.containerID)"]
        do {
            let status = try await container.accountStatus()
            let name: String
            switch status {
            case .available: name = "available"
            case .noAccount: name = "no iCloud account"
            case .restricted: name = "restricted"
            case .couldNotDetermine: name = "could not determine"
            case .temporarilyUnavailable: name = "temporarily unavailable"
            @unknown default: name = "unknown"
            }
            lines.append("iCloud account: \(name)")
        } catch {
            lines.append("iCloud account error: \(error.localizedDescription)")
        }
        lines.append("switch: \(enabled ? "on" : "off") · engine: \(engine != nil ? "running" : "stopped")")
        lines.append("Cloud plan: \(StoreManager.shared.hasCloud ? "active" : "not active") · test unlock: \(StoreManager.testUnlockActive ? "on" : "off")")
        lines.append("sample data: \(store.isDemo ? "yes (never synced)" : "no")")
        lines.append("records: \(store.data.recordCount) · pending: \(pendingCount)")
        if case .error(let message) = state { lines.append("error: \(message)") }
        return lines.joined(separator: "\n")
    }

    // MARK: Records

    private func makeRecord(_ entity: SyncEntity, id: CKRecord.ID) -> CKRecord? {
        guard let payload = try? entity.encoded() else { return nil }
        let name = id.recordName
        let record = file.fields[name].flatMap(Self.unarchive) ?? CKRecord(recordType: Self.recordType, recordID: id)
        record["kind"] = entity.kind.rawValue as CKRecordValue
        record["payload"] = payload as NSData
        record["modifiedAt"] = (file.modified[name] ?? Date()) as NSDate
        record["schema"] = Self.schema as CKRecordValue
        return record
    }

    private static func archive(_ record: CKRecord) -> Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return coder.encodedData
    }

    private static func unarchive(_ data: Data) -> CKRecord? {
        guard let coder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
        coder.requiresSecureCoding = true
        return CKRecord(coder: coder)
    }
}
