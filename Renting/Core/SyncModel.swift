//
//  SyncModel.swift
//  Renting
//
//  The pure part of iCloud sync (no CloudKit calls, so it can be tested offline): how the
//  data is cut into records, how a record turns back into data, and the rule that decides
//  who wins when two devices changed the same thing.
//
//  Every home, room, tenant, payment and expense is one record; the fiscal settings are one
//  more. A record holds the entity as JSON plus the time of its last change. Conflicts are
//  settled per record, last writer wins: two devices editing different records never
//  collide; two editing the same record keep the newer edit.
//

import CryptoKit
import Foundation

enum SyncKind: String, CaseIterable {
    case property, unit, tenant, payment, expense, settings
}

/// What is stored in the settings record.
struct SyncSettings: Codable, Hashable {
    var deductible: Set<ExpenseCategory>?
}

/// One synchronised thing, typed so that two of them can be compared by value.
enum SyncEntity: Hashable {
    case property(Property)
    case unit(Unit)
    case tenant(Tenant)
    case payment(Payment)
    case expense(Expense)
    case settings(SyncSettings)

    static let settingsName = "settings"

    var kind: SyncKind {
        switch self {
        case .property: .property
        case .unit: .unit
        case .tenant: .tenant
        case .payment: .payment
        case .expense: .expense
        case .settings: .settings
        }
    }

    /// The CloudKit record name: `kind-UUID`, or `settings`.
    var recordName: String {
        switch self {
        case .property(let v): "property-\(v.id.uuidString)"
        case .unit(let v): "unit-\(v.id.uuidString)"
        case .tenant(let v): "tenant-\(v.id.uuidString)"
        case .payment(let v): "payment-\(v.id.uuidString)"
        case .expense(let v): "expense-\(v.id.uuidString)"
        case .settings: Self.settingsName
        }
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        switch self {
        case .property(let v): return try encoder.encode(v)
        case .unit(let v): return try encoder.encode(v)
        case .tenant(let v): return try encoder.encode(v)
        case .payment(let v): return try encoder.encode(v)
        case .expense(let v): return try encoder.encode(v)
        case .settings(let v): return try encoder.encode(v)
        }
    }

    static func decode(kind: SyncKind, from data: Data) throws -> SyncEntity {
        let decoder = JSONDecoder()
        switch kind {
        case .property: return .property(try decoder.decode(Property.self, from: data))
        case .unit: return .unit(try decoder.decode(Unit.self, from: data))
        case .tenant: return .tenant(try decoder.decode(Tenant.self, from: data))
        case .payment: return .payment(try decoder.decode(Payment.self, from: data))
        case .expense: return .expense(try decoder.decode(Expense.self, from: data))
        case .settings: return .settings(try decoder.decode(SyncSettings.self, from: data))
        }
    }

    /// Splits a record name into its kind and entity id.
    static func parse(_ name: String) -> (kind: SyncKind, id: UUID?)? {
        if name == settingsName { return (.settings, nil) }
        guard let dash = name.firstIndex(of: "-"), let kind = SyncKind(rawValue: String(name[..<dash])),
              let id = UUID(uuidString: String(name[name.index(after: dash)...])) else { return nil }
        return (kind, id)
    }
}

extension Snapshot {
    /// Everything that is synchronised, by record name.
    var syncEntities: [String: SyncEntity] {
        var out: [String: SyncEntity] = [:]
        out.reserveCapacity(properties.count + units.count + tenants.count + payments.count + expenses.count + 1)
        func put(_ e: SyncEntity) { out[e.recordName] = e }
        properties.forEach { put(.property($0)) }
        units.forEach { put(.unit($0)) }
        tenants.forEach { put(.tenant($0)) }
        payments.forEach { put(.payment($0)) }
        expenses.forEach { put(.expense($0)) }
        put(.settings(SyncSettings(deductible: deductible)))
        return out
    }

    /// Applies changes that came from the cloud: inserts or replaces the entities and removes
    /// the deleted ones. Removing a home does not cascade here: the cloud already carries the
    /// deletion of its rooms, tenants and payments as records of their own.
    mutating func apply(_ upserts: [SyncEntity], deleting names: [String]) {
        func upsert<T: Identifiable>(_ list: inout [T], _ item: T) where T.ID == UUID {
            if let i = list.firstIndex(where: { $0.id == item.id }) { list[i] = item } else { list.append(item) }
        }
        for e in upserts {
            switch e {
            case .property(let v): upsert(&properties, v)
            case .unit(let v): upsert(&units, v)
            case .tenant(let v): upsert(&tenants, v)
            case .payment(let v): upsert(&payments, v)
            case .expense(let v): upsert(&expenses, v)
            case .settings(let v): deductible = v.deductible
            }
        }
        let gone = Dictionary(grouping: names.compactMap { SyncEntity.parse($0) }, by: \.kind).mapValues { Set($0.compactMap(\.id)) }
        if let ids = gone[.property] { properties.removeAll { ids.contains($0.id) } }
        if let ids = gone[.unit] { units.removeAll { ids.contains($0.id) } }
        if let ids = gone[.tenant] { tenants.removeAll { ids.contains($0.id) } }
        if let ids = gone[.payment] { payments.removeAll { ids.contains($0.id) } }
        if let ids = gone[.expense] { expenses.removeAll { ids.contains($0.id) } }
        if names.contains(SyncEntity.settingsName) { deductible = nil }
    }

    /// Record names that changed between two snapshots: `saved` are new or edited, `deleted` gone.
    static func syncDiff(from old: Snapshot, to new: Snapshot) -> (saved: [String], deleted: [String]) {
        diff(old.syncEntities, new.syncEntities)
    }

    static func diff(_ a: [String: SyncEntity], _ b: [String: SyncEntity]) -> (saved: [String], deleted: [String]) {
        (b.filter { a[$0.key] != $0.value }.map(\.key), a.keys.filter { b[$0] == nil })
    }

    /// Removes records whose parent no longer exists: a tenant added on one device to a room
    /// that another device deleted at the same time. Only call it once a download is complete
    /// (a parent may simply not have arrived yet while it is in progress).
    mutating func pruneOrphans() {
        let homes = Set(properties.map(\.id))
        units.removeAll { !homes.contains($0.propertyID) }
        let rooms = Set(units.map(\.id))
        tenants.removeAll { !rooms.contains($0.unitID) }
        let people = Set(tenants.map(\.id))
        payments.removeAll { !people.contains($0.tenantID) }
        expenses.removeAll { !homes.contains($0.propertyID) || ($0.unitID.map { !rooms.contains($0) } ?? false) }
    }

    /// How many records there are of every kind that can be orphaned.
    var recordCount: Int { properties.count + units.count + tenants.count + payments.count + expenses.count }

    /// Gives every payment the id derived from its tenant and month, merging duplicates. Two
    /// devices that tick the same month then write the same record instead of two.
    mutating func normalizePayments() {
        guard payments.contains(where: { $0.id != Payment.stableID(tenant: $0.tenantID, month: $0.month) }) else { return }
        var byID: [UUID: Payment] = [:]
        for var p in payments {
            p.id = Payment.stableID(tenant: p.tenantID, month: p.month)
            if let existing = byID[p.id], existing.paidOn > p.paidOn { continue }
            byID[p.id] = p
        }
        payments = byID.values.sorted { ($0.month, $0.tenantID.uuidString) < ($1.month, $1.tenantID.uuidString) }
    }
}

extension Payment {
    /// A fixed id for a tenant and month (a name-based UUID), the same on every device.
    static func stableID(tenant: UUID, month: MonthKey) -> UUID {
        let digest = Array(SHA256.hash(data: Data("renting.payment|\(tenant.uuidString)|\(month.id)".utf8)).prefix(16))
        var b = digest
        b[6] = (b[6] & 0x0F) | 0x50
        b[8] = (b[8] & 0x3F) | 0x80
        return UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
    }
}

enum SyncMerge {
    /// Last writer wins. On a tie the cloud wins, so every device settles on the same value.
    static func remoteWins(remote: Date, local: Date?) -> Bool {
        guard let local else { return true }
        return remote >= local
    }
}
