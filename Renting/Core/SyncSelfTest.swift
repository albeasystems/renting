//
//  SyncSelfTest.swift
//  Renting
//
//  Development only (compiled out of release): `-debugSyncTest 1` checks the offline part of
//  iCloud sync and prints one `SYNCTEST PASS|FAIL` line per check. The CloudKit round trip
//  itself needs an iCloud account and is exercised on a real device.
//

#if DEBUG
import CloudKit
import Foundation

enum SyncSelfTest {
    @MainActor
    static func run() {
        var failures = 0
        var report = ""
        func line(_ text: String) { print(text); report += text + "\n" }
        func check(_ name: String, _ ok: Bool, _ detail: String = "") {
            if !ok { failures += 1 }
            line("SYNCTEST \(ok ? "PASS" : "FAIL") \(name) \(detail)")
        }

        let demo = DemoData.make()
        let entities = demo.syncEntities

        // 1. Every entity survives encode → CKRecord field → decode, byte-order independent.
        var roundTripOK = true
        for (name, entity) in entities {
            guard let payload = try? entity.encoded() else { roundTripOK = false; break }
            let record = CKRecord(recordType: CloudSync.recordType, recordID: CKRecord.ID(recordName: name, zoneID: CloudSync.zoneID))
            record["payload"] = payload as NSData
            record["modifiedAt"] = Date() as NSDate
            guard let back = record["payload"] as? Data, let (kind, _) = SyncEntity.parse(name),
                  let decoded = try? SyncEntity.decode(kind: kind, from: back), decoded == entity else { roundTripOK = false; line("  failed on \(name)"); break }
        }
        check("record round trip", roundTripOK, "\(entities.count) records")

        // 2. Rebuilding a snapshot from its records gives the same data.
        var rebuilt = Snapshot()
        rebuilt.apply(Array(entities.values), deleting: [])
        check("rebuild from records", rebuilt.syncEntities == entities)

        // 3. Payments have one stable id per tenant and month.
        let t = demo.tenants[0].id
        let m = MonthKey(year: 2026, month: 3)
        check("stable payment id", Payment.stableID(tenant: t, month: m) == Payment.stableID(tenant: t, month: m)
              && Payment.stableID(tenant: t, month: m) != Payment.stableID(tenant: t, month: m.adding(1))
              && Payment.stableID(tenant: t, month: m) != Payment.stableID(tenant: demo.tenants[1].id, month: m))
        var legacy = demo
        legacy.payments = legacy.payments.map { var p = $0; p.id = UUID(); return p }
        let beforeCount = legacy.payments.count
        legacy.payments.append(legacy.payments[0])                       // a duplicate with the same tenant and month
        legacy.normalizePayments()
        check("legacy payments normalised", legacy.payments.count == beforeCount
              && Set(legacy.payments.map(\.id)) == Set(demo.payments.map(\.id)), "\(legacy.payments.count) of \(beforeCount)")
        let again = legacy.payments
        legacy.normalizePayments()
        check("normalising is idempotent", legacy.payments == again)

        // 4. Diffs: one edit is one record; a cascade delete lists everything that went.
        var edited = demo
        edited.tenants[0].monthlyRent += 10
        let d1 = Snapshot.syncDiff(from: demo, to: edited)
        check("one edit = one record", d1.saved == [SyncEntity.tenant(edited.tenants[0]).recordName] && d1.deleted.isEmpty, "\(d1.saved.count) saved")
        var cascade = demo
        let gone = cascade.properties[0].id
        let goneUnits = Set(cascade.units.filter { $0.propertyID == gone }.map(\.id))
        let goneTenants = Set(cascade.tenants.filter { goneUnits.contains($0.unitID) }.map(\.id))
        cascade.payments.removeAll { goneTenants.contains($0.tenantID) }
        cascade.tenants.removeAll { goneTenants.contains($0.id) }
        cascade.expenses.removeAll { $0.propertyID == gone }
        cascade.units.removeAll { goneUnits.contains($0.id) }
        cascade.properties.removeAll { $0.id == gone }
        let d2 = Snapshot.syncDiff(from: demo, to: cascade)
        let expectedGone = demo.payments.filter { goneTenants.contains($0.tenantID) }.count + goneTenants.count + goneUnits.count + 1
            + demo.expenses.filter { $0.propertyID == gone }.count
        check("cascade delete", d2.saved.isEmpty && d2.deleted.count == expectedGone, "\(d2.deleted.count) deleted, expected \(expectedGone)")
        var applied = demo
        applied.apply([], deleting: d2.deleted)
        check("deletions apply", applied.syncEntities == cascade.syncEntities)

        // 5. The fiscal settings travel too.
        var settings = demo
        settings.deductible = [.ibi, .community]
        var other = demo
        other.apply([.settings(SyncSettings(deductible: settings.deductible))], deleting: [])
        check("settings sync", other.deductible == [.ibi, .community])

        // 6. Last writer wins, and a tie goes to the cloud.
        let now = Date()
        check("merge: newer remote wins", SyncMerge.remoteWins(remote: now, local: now.addingTimeInterval(-5)))
        check("merge: older remote loses", !SyncMerge.remoteWins(remote: now.addingTimeInterval(-5), local: now))
        check("merge: tie goes to the cloud", SyncMerge.remoteWins(remote: now, local: now))
        check("merge: unknown local takes remote", SyncMerge.remoteWins(remote: .distantPast, local: nil))

        // 7. Two devices: edits to different records both survive; the same record keeps the newer one.
        var a = demo, b = demo
        a.tenants[0].monthlyRent = 111
        b.tenants[1].monthlyRent = 222
        let aSaved = Snapshot.syncDiff(from: demo, to: a).saved.compactMap { a.syncEntities[$0] }
        let bSaved = Snapshot.syncDiff(from: demo, to: b).saved.compactMap { b.syncEntities[$0] }
        a.apply(bSaved, deleting: []); b.apply(aSaved, deleting: [])
        check("two devices, different records", a.syncEntities == b.syncEntities && a.tenants[0].monthlyRent == 111 && a.tenants[1].monthlyRent == 222)
        var c = demo, d = demo
        c.tenants[0].monthlyRent = 300; d.tenants[0].monthlyRent = 400
        let cTime = now, dTime = now.addingTimeInterval(3)
        let dWins = SyncMerge.remoteWins(remote: dTime, local: cTime)
        if dWins { c.apply([.tenant(d.tenants[0])], deleting: []) }
        check("two devices, same record: newer wins", c.tenants[0].monthlyRent == 400)

        // 8. Data saved by an older version (no keys for newer fields) still decodes.
        if var json = (try? JSONSerialization.jsonObject(with: SyncEntity.tenant(demo.tenants[0]).encoded())) as? [String: Any] {
            ["rentChanges", "filing", "rentIndex", "reduction", "contract"].forEach { json.removeValue(forKey: $0) }
            let old = (try? JSONSerialization.data(withJSONObject: json)).flatMap { try? JSONDecoder().decode(Tenant.self, from: $0) }
            check("older tenant decodes", old != nil && old?.rentChanges == nil && old?.contract == nil)
        } else { check("older tenant decodes", false) }
        if var json = (try? JSONSerialization.jsonObject(with: SyncEntity.property(demo.properties[0]).encoded())) as? [String: Any] {
            ["cadastralValue", "cadastralRevised", "ownerResidence", "management"].forEach { json.removeValue(forKey: $0) }
            let old = (try? JSONSerialization.data(withJSONObject: json)).flatMap { try? JSONDecoder().decode(Property.self, from: $0) }
            check("older property decodes", old != nil && old?.cadastralRevised == false)
        } else { check("older property decodes", false) }

        // 9. Record names parse back.
        var namesOK = true
        for (name, e) in entities { if SyncEntity.parse(name)?.kind != e.kind { namesOK = false } }
        check("record names parse", namesOK && SyncEntity.parse("nonsense") == nil && SyncEntity.parse("tenant-xyz") == nil)

        // 10. Periods: calendar quarters start on 1 January, and the parts add up to the whole.
        func months(_ kind: PeriodKind, _ y: Int, _ m: Int) -> [Int] { ReportPeriod(kind: kind, anchor: MonthKey(year: y, month: m)).months.map(\.month) }
        check("quarter months", months(.quarter, 2026, 1) == [1, 2, 3] && months(.quarter, 2026, 3) == [1, 2, 3]
              && months(.quarter, 2026, 4) == [4, 5, 6] && months(.quarter, 2026, 9) == [7, 8, 9] && months(.quarter, 2026, 12) == [10, 11, 12])
        check("quarter number", [1, 3, 4, 6, 7, 9, 10, 12].map { ReportPeriod(kind: .quarter, anchor: MonthKey(year: 2026, month: $0)).quarter } == [1, 1, 2, 2, 3, 3, 4, 4])
        let q4 = ReportPeriod.quarter(4, of: 2026)
        check("quarter navigation", q4.moved(by: 1).quarter == 1 && q4.moved(by: 1).year == 2027
              && ReportPeriod.quarter(1, of: 2026).moved(by: -1).quarter == 4 && ReportPeriod.quarter(1, of: 2026).moved(by: -1).year == 2025)
        let dec = ReportPeriod(kind: .month, anchor: MonthKey(year: 2026, month: 12))
        check("month and year navigation", dec.moved(by: 1).anchor == MonthKey(year: 2027, month: 1)
              && ReportPeriod(kind: .year, anchor: dec.anchor).moved(by: -1).year == 2025)
        let store = RentalStore.shared
        if !store.isEmpty {
            let y = MonthKey.current.year
            let year = store.totals(ReportPeriod(kind: .year, anchor: MonthKey(year: y, month: 6)))
            let quarters = (1...4).map { store.totals(ReportPeriod.quarter($0, of: y)) }
            let monthsSum = MonthKey.months(of: y).map { store.totals(in: $0) }
            func close(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.01 }
            check("4 quarters = year (collected)", close(quarters.reduce(0) { $0 + $1.collected }, year.collected), "\(year.collected)")
            check("4 quarters = year (expenses)", close(quarters.reduce(0) { $0 + $1.expenses }, year.expenses), "\(year.expenses)")
            check("12 months = year (collected)", close(monthsSum.reduce(0) { $0 + $1.collected }, year.collected))
            let mp = store.chartPoints(for: ReportPeriod(kind: .month, anchor: .current))
            let qp = store.chartPoints(for: ReportPeriod(kind: .quarter, anchor: .current))
            let yp = store.chartPoints(for: ReportPeriod(kind: .year, anchor: .current))
            check("chart scales", mp.count == 12 && qp.count == 4 && yp.count >= 3 && yp.last?.label == String(y), "\(mp.count)/\(qp.count)/\(yp.count)")
            check("exactly one bar selected", [mp, qp, yp].allSatisfy { $0.filter(\.isSelected).count == 1 })
            check("quarter bars = year bar", close(qp.reduce(0) { $0 + $1.totals.collected }, yp.last?.totals.collected ?? -1))
            check("pending excludes future months", store.totals(ReportPeriod(kind: .year, anchor: .current)).pending
                  <= store.totals(months: MonthKey.months(of: y).filter { $0 <= .current }).pending + 0.01)
            let quick = store.incomeRows(ReportPeriod(kind: .month, anchor: .current)).reduce(0) { $0 + $1.amount }
            check("quick view income = month income", close(quick, store.totals(in: .current).collected), "\(quick)")
            let quickExp = store.chargeRows(in: .current).reduce(0) { $0 + $1.amount }
            check("quick view expenses = month expenses", close(quickExp, store.totals(in: .current).expenses), "\(quickExp)")
        }

        line("SYNCTEST DONE failures=\(failures)")
        try? report.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("synctest.txt"), atomically: true, encoding: .utf8)
    }
}
#endif
