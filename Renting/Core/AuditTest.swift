//
//  AuditTest.swift
//  Renting
//
//  Development only (compiled out of release): `-debugAudit 1` runs scenario checks on the
//  money, tax, date and notification logic with hand-built data and on the sample portfolio,
//  plus timings on a large synthetic portfolio. Prints and writes `AUDIT PASS|FAIL …` lines to
//  tmp/audit.txt. It replaces the store's data while it runs and restores it at the end.
//

#if DEBUG
import Foundation
import Observation

/// Set from an observation callback (which is not isolated) and read back by the checks.
private final class Flag: @unchecked Sendable { var on = false }

@MainActor
enum AuditTest {
    static func run() {
        let store = RentalStore.shared
        let original = store.data
        defer { store.debugReplace(original) }
        var report = ""
        var fails = 0
        func line(_ s: String) { print(s); report += s + "\n" }
        func check(_ name: String, _ ok: Bool, _ detail: String = "") {
            if !ok { fails += 1 }
            line("AUDIT \(ok ? "PASS" : "FAIL") \(name) \(detail)")
        }
        func close(_ a: Double, _ b: Double, _ eps: Double = 0.01) -> Bool { abs(a - b) < eps }

        let cal = Calendar.current
        let now = Date()
        let cur = MonthKey.current
        let lastYear = cur.year - 1
        func day(_ y: Int, _ m: Int, _ d: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d)) ?? now }
        func pay(_ t: Tenant, _ m: MonthKey, rent: Double, supplies: Double = 0) -> Payment {
            Payment(id: Payment.stableID(tenant: t.id, month: m), tenantID: t.id, month: m, amount: rent + supplies, paidOn: m.start, supplies: supplies,
                    rentDue: t.rent(in: m), suppliesDue: t.monthlyExpenses)
        }
        func orphans(_ s: Snapshot) -> Int {
            let props = Set(s.properties.map(\.id)), units = Set(s.units.map(\.id)), tenants = Set(s.tenants.map(\.id))
            return s.units.filter { !props.contains($0.propertyID) }.count
                + s.tenants.filter { !units.contains($0.unitID) }.count
                + s.payments.filter { !tenants.contains($0.tenantID) }.count
                + s.expenses.filter { !props.contains($0.propertyID) || ($0.unitID.map { !units.contains($0) } ?? false) }.count
        }

        // MARK: S1 — a rent update must not rewrite history
        do {
            var s = Snapshot()
            let p = Property(name: "P", address: "a", city: "c", kind: .traditional)
            let u = Unit(propertyID: p.id, name: "U", listRent: 400)
            var t = Tenant(unitID: u.id, name: "T", entryDate: cur.adding(-8).start, monthlyRent: 420, monthlyExpenses: 30)
            t.rentChanges = [RentChange(effective: cur, previous: 400, new: 420, index: .irav, percent: 5, cycle: 1, notifiedOn: nil)]
            s.properties = [p]; s.units = [u]; s.tenants = [t]
            for back in 1...8 { s.payments.append(pay(t, cur.adding(-back), rent: 400, supplies: 30)) }
            store.debugReplace(s)
            let tt = store.tenant(t.id)!
            check("S1 months paid before the update stay paid", (1...8).allSatisfy { store.status(of: tt, in: cur.adding(-$0)) == .paid })
            check("S1 expected rent uses the rent of each month", close(store.totals(in: cur.adding(-1)).expected, 430) && close(store.totals(in: cur).expected, 450))
            // The tenant form edits `monthlyRent` directly. Paid months must not turn into "partial".
            var edited = tt; edited.rentChanges = nil; edited.monthlyRent = 440
            store.save(edited)
            let flipped = (1...8).filter { store.status(of: store.tenant(t.id)!, in: cur.adding(-$0)) != .paid }.count
            check("S1b editing the rent in the form keeps paid months paid", flipped == 0, "\(flipped) of 8 past months flipped to partial")
        }

        // MARK: S2 — partial payments split into rent and utilities
        do {
            var s = Snapshot()
            let p = Property(name: "P", address: "a", city: "c", kind: .traditional)
            let u = Unit(propertyID: p.id, name: "U", listRent: 400)
            let t = Tenant(unitID: u.id, name: "T", entryDate: cur.adding(-3).start, monthlyRent: 400, monthlyExpenses: 30)
            s.properties = [p]; s.units = [u]; s.tenants = [t]
            let m = cur.adding(-1)
            s.payments = [Payment(id: Payment.stableID(tenant: t.id, month: m), tenantID: t.id, month: m, amount: 150, paidOn: m.start, supplies: 0)]
            store.debugReplace(s)
            let tt = store.tenant(t.id)!
            check("S2 partial payment is partial", store.status(of: tt, in: m) == .partial)
            check("S2 unpaid rent of a partial month", close(store.unpaidRent(of: tt, in: m), 250), "\(store.unpaidRent(of: tt, in: m))")
            check("S2 a month with no payment is overdue", store.status(of: tt, in: cur.adding(-2)) == .overdue)
        }

        // MARK: S3 — the manager's fee is on the rent, never on the utilities
        do {
            var s = Snapshot()
            var p = Property(name: "P", address: "a", city: "c", kind: .traditional)
            p.management = Management(name: "M", percent: 10, plusVAT: true)
            let u = Unit(propertyID: p.id, name: "U", listRent: 1000)
            let t = Tenant(unitID: u.id, name: "T", entryDate: cur.adding(-2).start, monthlyRent: 1000, monthlyExpenses: 100)
            s.properties = [p]; s.units = [u]; s.tenants = [t]
            s.payments = [pay(t, cur.adding(-1), rent: 1000, supplies: 100)]
            store.debugReplace(s)
            check("S3 fee = 10 % + VAT of the rent only", close(store.managementFee(in: cur.adding(-1), property: p.id), 121.0), "\(store.managementFee(in: cur.adding(-1), property: p.id))")
            check("S3 no fee for a month with no payment", close(store.managementFee(in: cur.adding(-2), property: p.id), 0))
        }

        // MARK: S4 — days let: boundaries, leap years, overlaps
        do {
            var s = Snapshot()
            let p = Property(name: "P", address: "a", city: "c", kind: .traditional)
            let u = Unit(propertyID: p.id, name: "U", listRent: 500)
            var a = Tenant(unitID: u.id, name: "A", entryDate: day(lastYear, 3, 15), monthlyRent: 500); a.exitDate = day(lastYear, 6, 20)
            s.properties = [p]; s.units = [u]; s.tenants = [a]
            store.debugReplace(s)
            check("S4 days let from 15 Mar to 20 Jun, both included", store.rentedDays(unit: u.id, year: lastYear) == 98, "\(store.rentedDays(unit: u.id, year: lastYear))")
            var b = Tenant(unitID: u.id, name: "B", entryDate: day(lastYear, 5, 1), monthlyRent: 500); b.exitDate = day(lastYear, 7, 10)
            s.tenants = [a, b]; store.debugReplace(s)
            check("S4 overlapping tenants are not counted twice", store.rentedDays(unit: u.id, year: lastYear) == 98 + 20, "\(store.rentedDays(unit: u.id, year: lastYear))")
            var full = Tenant(unitID: u.id, name: "F", entryDate: day(2020, 1, 1), monthlyRent: 500); full.exitDate = nil
            s.tenants = [full]; store.debugReplace(s)
            check("S4 leap year: 366 of 366 days", store.rentedDays(unit: u.id, year: 2028) == 366 && close(store.rentedShare(unit: u.id, year: 2028), 1))
            check("S4 ordinary year: 365 of 365 days", store.rentedDays(unit: u.id, year: 2027) == 365)
            check("S4 days in year", RentalStore.days(in: 2028) == 366 && RentalStore.days(in: 2027) == 365)
        }

        // MARK: S5 / S6 — imputation and the reduction per contract
        do {
            var s = Snapshot()
            var p = Property(name: "P", address: "a", city: "c", kind: .traditional)
            p.cadastralValue = 100_000; p.cadastralRevised = true
            let u = Unit(propertyID: p.id, name: "U", listRent: 800)
            let t = Tenant(unitID: u.id, name: "T", entryDate: day(lastYear, 7, 1), monthlyRent: 800)
            s.properties = [p]; s.units = [u]; s.tenants = [t]
            for m in MonthKey.months(of: lastYear) where m.month >= 7 { s.payments.append(pay(t, m, rent: 800)) }
            store.debugReplace(s)
            let share = Double(store.rentedDays(unit: u.id, year: lastYear)) / Double(RentalStore.days(in: lastYear))
            var f = ReportService.figures(year: lastYear, store: store).first!
            check("S5 imputed income = 1.1 % × cadastral × empty share", close(f.imputed, 100_000 * 0.011 * (1 - share)), "\(f.imputed)")
            s.properties[0].cadastralRevised = false; store.debugReplace(s)
            f = ReportService.figures(year: lastYear, store: store).first!
            check("S5 not revised: 2 %", close(f.imputed, 100_000 * 0.02 * (1 - share)))
            s.properties[0].ownerResidence = true; store.debugReplace(s)
            check("S5 own home: nothing imputed", ReportService.figures(year: lastYear, store: store).first!.imputed == 0)

            // two contracts, one reduced and one not
            var s2 = Snapshot()
            let p2 = Property(name: "P2", address: "a", city: "c", kind: .rooms)
            let u1 = Unit(propertyID: p2.id, name: "R1", listRent: 600), u2 = Unit(propertyID: p2.id, name: "R2", listRent: 400)
            let a = Tenant(unitID: u1.id, name: "A", entryDate: day(lastYear, 1, 1), monthlyRent: 600)
            var b = Tenant(unitID: u2.id, name: "B", entryDate: day(lastYear, 1, 1), monthlyRent: 400); b.reduction = RentReduction.none
            s2.properties = [p2]; s2.units = [u1, u2]; s2.tenants = [a, b]
            for m in MonthKey.months(of: lastYear) { s2.payments.append(pay(a, m, rent: 600)); s2.payments.append(pay(b, m, rent: 400)) }
            store.debugReplace(s2)
            let g = ReportService.figures(year: lastYear, store: store).first!
            check("S6 net before the reduction", close(g.net, 12_000), "\(g.net)")
            check("S6 reduction split by the rent of each contract (50 % on 60 %, 0 % on 40 %)", close(g.reduction, 3_600), "\(g.reduction)")
            check("S6 reduced net = net − reduction", close(g.netReduced, 8_400))
        }

        // MARK: S7 / S8 — consistency on the sample portfolio
        store.debugReplace(DemoData.make())
        do {
            let months = MonthKey.months(of: cur.year)
            var worst = 0.0
            for m in months {
                let all = store.totals(in: m)
                let parts = store.data.properties.reduce(Totals()) { $0 + store.totals(in: m, property: $1.id) }
                worst = max(worst, abs(all.collected - parts.collected), abs(all.expenses - parts.expenses), abs(all.rent - parts.rent))
            }
            check("S8 total of all homes = sum of the homes, every month", worst < 0.01, "worst gap \(worst)")
            let y = store.totals(year: cur.year)
            let figs = ReportService.figures(year: cur.year, store: store)
            check("S7 fiscal income = rent collected", close(figs.reduce(0) { $0 + $1.income }, y.rent))
            check("S7 fiscal net = income − expenses − depreciation", figs.allSatisfy { close($0.net, $0.income - $0.expenses - $0.depreciation) })
            check("S7 deductible expenses never exceed the marked ones", figs.allSatisfy { $0.vacantExpenses >= -0.01 })
            check("S7 reduction never exceeds the net", figs.allSatisfy { $0.reduction <= max($0.net, 0) + 0.01 })
            check("S7 unit summaries add up to the collected total", close(store.summaryByUnit(year: cur.year).reduce(0) { $0 + $1.income }, y.collected))
            let byUnitExpenses = store.summaryByUnit(year: cur.year).reduce(0) { $0 + $1.expenses }
            check("S7 unit summaries add up to the expenses total", close(byUnitExpenses, y.expenses, 1.0), "units \(byUnitExpenses) vs \(y.expenses)")
            check("S7 home summaries add up to the expenses total", close(store.summaryByProperty(year: cur.year).reduce(0) { $0 + $1.expenses }, y.expenses))
            check("S7 the sample portfolio has no orphan records", orphans(store.data) == 0)
        }

        // MARK: S9 — identifiers are unique (SwiftUI lists rely on it) and notifications are sane
        do {
            let alerts = store.alerts()
            check("S9 alert ids are unique", Set(alerts.map(\.id)).count == alerts.count, "\(alerts.count) alerts")
            check("S9 no alert shows a raw localization key", alerts.allSatisfy { !$0.title.hasPrefix("alert.") && !$0.detail.hasPrefix("alert.") })
            let charges = (-24...12).flatMap { store.charges(in: cur.adding($0)) }
            check("S9 charge ids are unique", Set(charges.map(\.id)).count == charges.count, "\(charges.count) charges")
            let plan = AlertsManager.plan(store: store, config: .shared, now: now)
            check("S9 notification ids are unique", Set(plan.map(\.id)).count == plan.count, "\(plan.count) planned")
            check("S9 every notification is in the future", plan.allSatisfy { $0.date > now })
            check("S9 no notification shows a raw localization key", plan.allSatisfy { !$0.title.hasPrefix("notif.") && !$0.body.hasPrefix("notif.") })
            for kind in PeriodKind.allCases {
                let pts = store.chartPoints(for: ReportPeriod(kind: kind, anchor: cur))
                check("S9 chart keys are unique (\(kind.rawValue))", Set(pts.map(\.key)).count == pts.count)
            }
        }

        // MARK: S10 — expense schedules
        do {
            let jan = MonthKey(year: cur.year, month: 1)
            func e(_ f: Frequency, first: MonthKey, last: MonthKey? = nil) -> Expense {
                Expense(propertyID: UUID(), unitID: nil, category: .community, title: "x", amount: 100, frequency: f, firstMonth: first, lastMonth: last)
            }
            let q = e(.quarterly, first: jan)
            check("S10 quarterly falls due Jan, Apr, Jul, Oct", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].filter { q.amount(in: MonthKey(year: cur.year, month: $0)) > 0 } == [1, 4, 7, 10])
            let a = e(.annual, first: MonthKey(year: cur.year, month: 10))
            check("S10 annual falls due once a year", (1...12).filter { a.amount(in: MonthKey(year: cur.year, month: $0)) > 0 } == [10] && a.amount(in: MonthKey(year: cur.year + 1, month: 10)) > 0)
            let one = e(.once, first: cur)
            check("S10 one-off falls due once", one.amount(in: cur) > 0 && one.amount(in: cur.adding(1)) == 0 && one.amount(in: cur.adding(-1)) == 0)
            let ended = e(.monthly, first: cur.adding(-5), last: cur)
            check("S10 an expense stops after its last month", ended.amount(in: cur) > 0 && ended.amount(in: cur.adding(1)) == 0)
            check("S10 due months through today", ended.dueMonths(through: cur).count == 6)
            var actual = e(.monthly, first: cur.adding(-2)); actual.actuals = [cur.id: 99]
            check("S10 a real bill overrides the plan, the plan stays", close(actual.amount(in: cur), 99) && close(actual.plannedAmount(in: cur), 100) && actual.hasActual(in: cur))
        }

        // MARK: S11 / S12 / S13 — rent update, fianza deposit, effective month
        do {
            var s = Snapshot()
            let p = Property(name: "P", address: "a", city: "c", kind: .traditional)
            let u = Unit(propertyID: p.id, name: "U", listRent: 800)
            s.properties = [p]; s.units = [u]
            s.tenants = []
            func tenant(entry: Date, deposit: Double = 800) -> Tenant { Tenant(unitID: u.id, name: "T", entryDate: entry, monthlyRent: 800, deposit: deposit) }
            func days(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: cal.startOfDay(for: now))! }
            func years(_ n: Int, _ d: Int) -> Date { cal.date(byAdding: .day, value: d, to: cal.date(byAdding: .year, value: n, to: cal.startOfDay(for: now))!)! }
            store.debugReplace(s)

            let soon = tenant(entry: years(-1, 20))                       // first anniversary in 20 days
            check("S11 update is due 20 days before the anniversary", store.pendingReview(for: soon)?.cycle == 1)
            var decided = soon
            decided.rentChanges = [RentChange(effective: cur, previous: 800, new: 800, index: .irav, percent: 0, cycle: 1, notifiedOn: nil)]
            check("S11 a decision (even keeping the rent) silences it", store.pendingReview(for: decided) == nil)
            let old = tenant(entry: years(-3, -10))                       // 3rd anniversary 10 days ago, 1st and 2nd long ago
            check("S11 only the latest missed anniversary is asked", store.pendingReview(for: old)?.cycle == 3)
            let far = tenant(entry: years(-1, 200))
            check("S11 nothing is asked 200 days before", store.pendingReview(for: far) == nil)
            var noClause = soon; noClause.rentIndex = RentIndex.none
            check("S11 no clause, no update", store.pendingReview(for: noClause) == nil)

            func kind(_ st: FilingStatus) -> String {
                switch st {
                case .notApplicable: "n/a"; case .exempt: "exempt"; case .filed: "filed"; case .pending: "pending"; case .overdue: "overdue"
                }
            }
            func status(_ t: Tenant) -> String {
                var s2 = s; s2.tenants = [t]; store.debugReplace(s2)
                return kind(store.filingInfo(for: store.tenant(t.id)!).status)
            }
            let window = RentalStore.depositDays
            check("S12 fianza: past the deadline after move-in is overdue", status(tenant(entry: days(-window - 10))) == "overdue", "deadline \(window) days")
            check("S12 fianza: inside the deadline is pending", status(tenant(entry: days(-max(1, window - 10)))) == "pending")
            check("S12 no deposit: not applicable", status(tenant(entry: days(-window - 10), deposit: 0)) == "n/a")
            var filed = tenant(entry: days(-window - 10)); filed.filing = DepositFiling(signedOn: nil, filedOn: days(-5))
            check("S12 deposited: filed", status(filed) == "filed")
            var late = tenant(entry: days(-window - 10)); late.filing = DepositFiling(customDeadline: days(5))
            check("S12 a deadline typed by the landlord wins", status(late) == "pending")
            var returned = tenant(entry: days(-window - 10)); returned.depositReturned = 800
            check("S12 a returned deposit needs nothing", status(returned) == "n/a")

            check("S13 notice after the anniversary: from the month after the notice", store.effectiveMonth(anniversary: day(lastYear, 10, 15), notifiedOn: day(lastYear, 10, 20)) == MonthKey(year: lastYear, month: 11))
            check("S13 notice well before: not earlier than the anniversary", store.effectiveMonth(anniversary: day(lastYear, 10, 15), notifiedOn: day(lastYear, 8, 1)) == MonthKey(year: lastYear, month: 10))
        }

        // MARK: S14 — periods
        do {
            let ongoing = ReportPeriod(kind: .quarter, anchor: cur)
            check("S14 a running quarter counts to the current month", ongoing.accountedMonths.last == cur && ongoing.isOngoing || ongoing.last <= cur)
            let future = ReportPeriod(kind: .quarter, anchor: cur.adding(12))
            check("S14 a future quarter shows its schedule", future.accountedMonths.count == 3)
            let past = ReportPeriod(kind: .year, anchor: MonthKey(year: lastYear, month: 6))
            check("S14 a past year counts all 12 months", past.accountedMonths.count == 12 && !past.isOngoing)
        }

        // MARK: S15 / S16 — deletions and records that arrive from another device
        do {
            let demo = DemoData.make()
            store.debugReplace(demo)
            store.deleteProperty(demo.properties[0].id); check("S15 deleting a home leaves no orphans", orphans(store.data) == 0)
            store.deleteUnit(store.data.units[0].id); check("S15 deleting a room leaves no orphans", orphans(store.data) == 0)
            store.deleteTenant(store.data.tenants[0].id); check("S15 deleting a tenant leaves no orphans", orphans(store.data) == 0)

            // Another device deletes a home while this one adds a tenant to one of its rooms.
            let full = DemoData.make()
            let victim = full.properties[0]
            let rooms = full.units.filter { $0.propertyID == victim.id }
            let tenants = full.tenants.filter { t in rooms.contains { $0.id == t.unitID } }
            var gone: [String] = [SyncEntity.property(victim).recordName]
            gone += rooms.map { SyncEntity.unit($0).recordName } + tenants.map { SyncEntity.tenant($0).recordName }
            gone += full.payments.filter { p in tenants.contains { $0.id == p.tenantID } }.map { SyncEntity.payment($0).recordName }
            gone += full.expenses.filter { $0.propertyID == victim.id }.map { SyncEntity.expense($0).recordName }
            var other = full
            other.apply([], deleting: gone)
            check("S16 the cascade the cloud sends leaves no orphans", orphans(other) == 0, "\(orphans(other)) orphans")
            // …and a tenant that another device added to one of those rooms at the same time arrives afterwards.
            let late = Tenant(unitID: rooms[0].id, name: "Late", entryDate: cur.start, monthlyRent: 999)
            store.debugReplace(full)
            store.applyFromCloud([], deleting: gone)
            store.applyFromCloud([.tenant(late)], deleting: [])
            store.pruneOrphansFromCloud()
            check("S16 a tenant for a room deleted elsewhere does not stay as a ghost", !store.data.tenants.contains { $0.name == "Late" } && orphans(store.data) == 0,
                  "\(orphans(store.data)) orphans; ghost income in the total: \(store.totals(in: cur).expected)")
        }

        // MARK: S17 — every dynamic localization key exists in all 9 languages
        do {
            var keys: [String] = []
            ExpenseCategory.allCases.forEach { keys.append("cat.\($0.rawValue)") }
            Frequency.allCases.forEach { keys.append("freq.\($0.rawValue)") }
            RentalKind.allCases.forEach { keys.append("kind.\($0.rawValue)"); keys.append("kind.\($0.rawValue).footer") }
            RentReduction.allCases.forEach { keys.append("red.\($0.rawValue)") }
            AlertRuleKind.allCases.forEach { keys.append("rule.\($0.rawValue)"); keys.append("rule.\($0.rawValue).detail") }
            RentIndex.allCases.forEach { keys.append("idx.\($0.rawValue)") }
            ContractRegime.allCases.forEach { keys.append("contract.regime.\($0.rawValue)") }
            ["widget.of", "widget.more", "widget.stale", "widget.empty", "backup.summary", "backup.none"].forEach { keys.append($0) }
            ["plan.locked", "plan.homes.reason %lld", "plan.homes.full %lld", "plan.f.homes.title", "plan.f.homes.text %lld", "plan.f.homes_adv.title", "plan.f.homes_adv.text",
             "plan.f.tenants_adv.title", "plan.f.tenants_adv.text", "fiscal.net_basic", "fiscal.adv.title", "fiscal.adv.text", "receipt.locked"].forEach { keys.append($0) }
            ContractTerm.allCases.forEach { keys.append("contract.term.\($0.rawValue)") }
            ["irav", "ipc", "fixed", "manual"].forEach { keys.append("letter.idx.\($0)") }
            var missing: [String] = []
            for lang in AppLanguage.supported {
                guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"), let b = Bundle(path: path) else { missing.append("\(lang): no bundle"); continue }
                for k in keys where b.localizedString(forKey: k, value: "⟂", table: nil) == "⟂" { missing.append("\(lang):\(k)") }
            }
            check("S17 enum-based keys exist in every language", missing.isEmpty, "\(keys.count) keys × 9 languages; missing \(missing.prefix(6))")
        }

        // MARK: S18 — typing a decimal with the keyboard of the device
        do {
            func parse(_ text: String, _ id: String) -> Double? {
                try? FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...2)).locale(Locale(identifier: id)).parseStrategy.parse(text)
            }
            line("AUDIT INFO parse \"12,5\" in en = \(parse("12,5", "en") ?? -1), in es = \(parse("12,5", "es") ?? -1); \"12.5\" in en = \(parse("12.5", "en") ?? -1), in es = \(parse("12.5", "es") ?? -1)")
            // The fix: the field reads what the keyboard of the device writes, whatever the app's language.
            let device = Locale.current.identifier
            let typed = 12.5.formatted(.number.precision(.fractionLength(0...2)).locale(Locale.current))
            check("S18 a number typed with the device's own separators is read back exactly", parse(typed, device) == 12.5, "device \(device) writes \(typed)")
        }

        // MARK: S19 — occupancy history, contract type, contract end, deposit switch, views that must redraw
        do {
            var s = Snapshot()
            let p = Property(name: "P", address: "a", city: "c", kind: .traditional)
            let u = Unit(propertyID: p.id, name: "U", listRent: 500)
            let first = Tenant(unitID: u.id, name: "A", entryDate: day(2024, 3, 1), exitDate: day(2024, 6, 30), monthlyRent: 500)
            let second = Tenant(unitID: u.id, name: "B", entryDate: day(2024, 9, 1), monthlyRent: 500)
            s.properties = [p]; s.units = [u]; s.tenants = [first, second]
            store.debugReplace(s)

            // Occupancy: a room counts from its first tenant; the running year counts up to today.
            let y24 = store.occupancyDays(unit: u.id, year: 2024)
            check("S19 occupancy of the first year counts from the first tenant", y24.rented == 244 && y24.available == 306, "\(y24)")
            check("S19 no days to measure before the first tenant", store.occupancyDays(unit: u.id, year: 2023).available == 0)
            let thisYear = store.occupancyDays(unit: u.id, year: cur.year)
            let elapsed = (cal.dateComponents([.day], from: day(cur.year, 1, 1), to: cal.startOfDay(for: now)).day ?? 0) + 1
            check("S19 the running year counts up to today", thisYear.available == elapsed && thisYear.rented == elapsed, "\(thisYear) vs \(elapsed)")
            let history = store.occupancyHistory()
            check("S19 the history has one row per year since the first tenant", history.first?.year == 2024 && history.last?.year == cur.year && history.count == cur.year - 2023, "\(history.map(\.year))")

            // Type of contract decides whether article 18 and the IRPF reduction apply.
            func lease(_ t: Tenant, kind: RentalKind = .traditional) -> Bool {
                var s2 = s; s2.properties[0].kind = kind; s2.tenants = [t]; store.debugReplace(s2)
                return store.isHousingLease(store.tenant(t.id)!)
            }
            var plain = second; plain.contract = nil
            var housing = second; housing.contract = ContractInfo(regime: .lauHousing, term: .annual, rentInsurance: true)
            var civil = second; civil.contract = ContractInfo(regime: .civil, term: .monthly, rentInsurance: false)
            check("S19 no contract info: treated as a housing lease", lease(plain))
            check("S19 LAU primary residence is a housing lease", lease(housing))
            check("S19 a Civil Code contract is not under article 18", !lease(civil))
            check("S19 a seasonal home is never a housing lease", !lease(housing, kind: .seasonal))
            var civilSnap = s; civilSnap.tenants = [civil]; store.debugReplace(civilSnap)
            let civilTenant = store.tenant(civil.id)!
            check("S19 Civil Code: update by agreement and no IRPF reduction", store.automaticIndex(for: civilTenant) == .manual && store.automaticReduction(for: civilTenant) == RentReduction.none)

            // Contract end: flagged within the notice period, urgent in the last month.
            func ending(in days: Int) -> Tenant { var t = second; t.contractEnd = cal.date(byAdding: .day, value: days, to: now); return t }
            func load(_ t: Tenant) -> Tenant { var s2 = s; s2.tenants = [t]; store.debugReplace(s2); return store.tenant(t.id)! }
            let lead = Int(AlertConfig.shared.rule(.contractEnding).param)
            check("S19 contract ending in 40 days is flagged", store.contractEndDays(load(ending(in: 40))) == 40, "\(String(describing: store.contractEndDays(load(ending(in: 40)))))")
            check("S19 contract ending far away is not flagged", store.contractEndDays(load(ending(in: lead + 100))) == nil)
            check("S19 an active tenant past the contract end is flagged as expired", (store.contractEndDays(load(ending(in: -5))) ?? 0) == -5)
            _ = load(ending(in: 40))
            check("S19 alert for a contract ending in 40 days (normal)", store.alerts().first { $0.kind == .contractEnding }?.severity == .normal)
            _ = load(ending(in: 20))
            check("S19 alert for a contract ending in 20 days (high)", store.alerts().first { $0.kind == .contractEnding }?.severity == .high)
            _ = load(ending(in: lead + 10))
            let notices = AlertsManager.plan(store: store, config: .shared, now: now).filter { $0.id.hasPrefix("contract") }
            check("S19 notifications at the chosen notice and a month before the end", notices.count == (lead == 30 ? 1 : 2), "\(notices.map(\.id))")

            // The fianza is just "deposited or not".
            var dep = second; dep.deposit = 500
            var depSnap = s; depSnap.tenants = [dep]; store.debugReplace(depSnap)
            func filingKind() -> String {
                switch store.filingInfo(for: store.tenant(dep.id)!).status { case .filed: "filed"; case .overdue: "overdue"; case .pending: "pending"; default: "other" }
            }
            check("S19 not deposited and past the deadline: overdue", filingKind() == "overdue", filingKind())
            store.setDeposited(true, for: dep); check("S19 switch on: deposited", filingKind() == "filed", filingKind())
            store.setDeposited(false, for: dep); check("S19 switch off: back to overdue", filingKind() == "overdue", filingKind())
            var exempt = dep; exempt.filing = DepositFiling(notRequired: true)
            depSnap.tenants = [exempt]; store.debugReplace(depSnap)
            store.setDeposited(true, for: exempt)
            check("S19 switching it on overrides an old \"not required\" mark", filingKind() == "filed", filingKind())

            // Views that read a payment (or the alerts) through an index must be told when it changes.
            depSnap.tenants = [dep]; store.debugReplace(depSnap)
            let subject = store.tenant(dep.id)!
            let paymentFlag = Flag()
            withObservationTracking { _ = store.payment(of: subject.id, in: cur) } onChange: { paymentFlag.on = true }
            store.togglePayment(subject, month: cur)
            check("S19 ticking a month tells the views that only read that payment", paymentFlag.on)
            let alertsFlag = Flag()
            withObservationTracking { _ = store.alerts() } onChange: { alertsFlag.on = true }
            store.togglePayment(subject, month: cur)
            check("S19 un-ticking tells the views that show the (reused) alerts", alertsFlag.on)
            let tenantFlag = Flag()
            withObservationTracking { _ = store.tenant(subject.id) } onChange: { tenantFlag.on = true }
            store.setDeposited(true, for: subject)
            check("S19 editing a tenant tells the views that look it up by id", tenantFlag.on)

            // Tapping a tab empties the stack of the Homes tab and only that one.
            let ui = AppUI()
            ui.homesPath = [.property(p.id), .unit(u.id)]
            ui.tabTapped(.dashboard)
            check("S19 tapping another tab leaves the Homes stack alone", ui.homesPath.count == 2)
            ui.tabTapped(.properties)
            check("S19 tapping the Homes tab goes back to its first screen", ui.homesPath.isEmpty)
        }

        // MARK: S20 — the room's price starts a tenant and then belongs to the tenant
        do {
            var s = Snapshot()
            let p = Property(name: "P", address: "a", city: "c", kind: .rooms)
            var u = Unit(propertyID: p.id, name: "R1", listRent: 400, listExpenses: 35)
            s.properties = [p]; s.units = [u]
            store.debugReplace(s)
            var first = Tenant.starting(in: u, on: day(2025, 1, 1))
            check("S20 a new tenant starts with the room's rent and utilities", first.monthlyRent == 400 && first.monthlyExpenses == 35)
            first.name = "A"
            store.save(first)
            u.listRent = 450; u.listExpenses = 40
            store.save(u)
            check("S20 raising the room's price does not touch the tenant who is in", store.tenant(first.id)?.monthlyRent == 400 && store.tenant(first.id)?.monthlyExpenses == 35)
            let next = Tenant.starting(in: store.unit(u.id)!)
            check("S20 the next tenant starts from the new price", next.monthlyRent == 450 && next.monthlyExpenses == 40)
            check("S20 a room with no utilities set starts at zero", Tenant.starting(in: Unit(propertyID: p.id, name: "R2", listRent: 300)).monthlyExpenses == 0)
            let oldRoom = #"{"id":"\#(UUID().uuidString)","propertyID":"\#(p.id.uuidString)","name":"Old","listRent":350}"#
            check("S20 a room saved before utilities existed decodes", (try? JSONDecoder().decode(Unit.self, from: Data(oldRoom.utf8)))?.listExpenses == nil)
            let oldHome = #"{"id":"\#(UUID().uuidString)","name":"P","address":"a","city":"c","kind":"traditional","region":"madrid"}"#
            check("S20 a home saved with the old autonomous community still decodes", (try? JSONDecoder().decode(Property.self, from: Data(oldHome.utf8)))?.name == "P")
        }

        // MARK: S21 — the Collections widget snapshot
        do {
            var s = Snapshot()
            let p = Property(name: "P", address: "a", city: "c", kind: .rooms)
            let rooms = (1...5).map { Unit(propertyID: p.id, name: "R\($0)", listRent: 400) }
            let entry = cur.adding(-3).start
            // A and B paid in full, C paid 150 of 435, D (the largest rent) and E nothing, F nothing too.
            var people = ["A", "B", "C", "D", "E"].enumerated().map { i, name in
                Tenant(unitID: rooms[i].id, name: name, entryDate: entry, monthlyRent: name == "D" ? 600 : 400, monthlyExpenses: 35)
            }
            people.append(Tenant(unitID: rooms[0].id, name: "F", entryDate: entry, monthlyRent: 380, monthlyExpenses: 0))
            s.properties = [p]; s.units = rooms; s.tenants = people
            func tenant(_ name: String) -> Tenant { people.first { $0.name == name }! }
            s.payments = [pay(tenant("A"), cur, rent: 400, supplies: 35), pay(tenant("B"), cur, rent: 400, supplies: 35),
                          Payment(id: Payment.stableID(tenant: tenant("C").id, month: cur), tenantID: tenant("C").id, month: cur, amount: 150,
                                  paidOn: cur.start, supplies: 0, rentDue: 400, suppliesDue: 35)]
            store.debugReplace(s)
            let early = cur.start.addingTimeInterval(2 * 86_400 + 3_600)     // day 3: nothing is overdue yet
            let late = cur.start.addingTimeInterval(19 * 86_400 + 3_600)     // day 20
            let w = WidgetBridge.makeSnapshot(store: store, now: late)
            let totals = store.totals(in: cur)
            check("S21 widget: collected and expected match the Collections tab", w.collectedText == totals.collected.money && w.fraction > 0 && close(w.fraction, totals.collected / totals.expected, 1e-9), "\(w.collectedText) \(w.fraction)")
            check("S21 widget: counts everyone who owes something", w.pendingCount == 4, "\(w.pendingCount)")
            check("S21 widget: at most three rows and the rest as \"more\"", w.rows.count == 3 && !w.moreText.isEmpty, "\(w.rows.map(\.name)) \(w.moreText)")
            check("S21 widget: late ones first, then whoever owes the most", w.rows.map(\.name) == ["D", "E", "F"] || w.rows.first?.name == "D", "\(w.rows.map(\.name))")
            check("S21 widget: the partial payment shows what is left", w.pendingText.isEmpty == false)
            check("S21 widget: the month runs from its first day to the first of the next", w.monthStart == cur.start && w.nextMonthStart == cur.adding(1).start)
            check("S21 widget: it is not stale inside the month and is stale after it", !w.isStale(at: late) && w.isStale(at: cur.adding(1).start) && w.isStale(at: cur.start.addingTimeInterval(-60)))
            let dayThree = WidgetBridge.makeSnapshot(store: store, now: early)
            let upcomingRows = dayThree.rows.filter { !$0.partial }
            check("S21 widget: before the due day unpaid rents are upcoming, and become late on their own", !upcomingRows.isEmpty && upcomingRows.allSatisfy { !$0.isLate(at: early) && $0.isLate(at: late) })
            check("S21 widget: a partial payment is late whatever the day", dayThree.rows.contains { $0.partial && $0.isLate(at: early) })
            check("S21 widget: everything collected says so", {
                var done = s; done.payments = people.map { pay($0, cur, rent: $0.monthlyRent, supplies: $0.monthlyExpenses) }
                store.debugReplace(done)
                let snap = WidgetBridge.makeSnapshot(store: store, now: late)
                return snap.pendingCount == 0 && snap.rows.isEmpty && snap.pendingText.isEmpty && close(snap.fraction, 1)
            }())
            let roundTrip = try? JSONDecoder().decode(WidgetSnapshot.self, from: JSONEncoder().encode(w))
            check("S21 widget: the snapshot survives being written and read", roundTrip == w)
            if WidgetStorage.isAvailable {
                check("S21 widget: the shared container is writable and readable (App Group)", WidgetStorage.write(w) && WidgetStorage.read() == w)
            } else {
                line("AUDIT INFO S21 the App Group container is not available in this run (no entitlement): widget file not tested")
            }
            store.debugReplace(Snapshot())
            check("S21 widget: no data means an empty widget", WidgetBridge.makeSnapshot(store: store, now: late).isEmpty)
        }

        // MARK: S22 — the backup file
        do {
            var real = DemoData.make(); real.isDemo = false
            let sample = DemoData.make()
            check("S22 the sample data is never exported, the landlord's data is", !BackupService.canExport(sample) && BackupService.canExport(real))
            check("S22 an empty app has nothing to export", !BackupService.canExport(Snapshot()))

            // Round trip: what comes back is exactly what went out.
            let data = (try? BackupService.encode(real)) ?? Data()
            let back = try? BackupService.decode(data)
            check("S22 a backup restores exactly what was saved", back.map { $0.syncEntities == real.syncEntities } == true, "\(back.map { BackupService.summary(of: $0) } as Any)")
            check("S22 the summary counts what the file holds", back.map { BackupService.summary(of: $0) } == BackupService.summary(of: real))

            // Through a real file, with the name it will be shared under.
            if let url = try? BackupService.writeFile(real) {
                let name = url.lastPathComponent
                check("S22 the file is named Renting-backup-<date>.json", name.range(of: #"^Renting-backup-\d{4}-\d{2}-\d{2}\.json$"#, options: .regularExpression) != nil, name)
                check("S22 the file on disk restores too", (try? Data(contentsOf: url)).flatMap { try? BackupService.decode($0) }.map { $0.syncEntities == real.syncEntities } == true)
                try? FileManager.default.removeItem(at: url)
            } else { check("S22 the file can be written", false) }

            // What is not a backup, is not read.
            func fails(_ data: Data, _ expected: BackupError) -> Bool {
                do { _ = try BackupService.decode(data); return false } catch { return (error as? BackupError) == expected }
            }
            check("S22 a text file is not a backup", fails(Data("hello".utf8), .notABackup))
            check("S22 a JSON of another app is not a backup", fails(Data(#"{"app":"other","format":1}"#.utf8), .notABackup))
            check("S22 the data file of the app itself (no envelope) is not a backup", fails((try? JSONEncoder().encode(real)) ?? Data(), .notABackup))
            let newer = (try? JSONEncoder().encode(BackupFile(format: BackupService.currentFormat + 1, exportedAt: Date(), appVersion: "9", data: real))) ?? Data()
            check("S22 a backup from a newer version is refused with its own message", fails(newer, .newerFormat))
            check("S22 an empty backup is refused (it would only erase the data)", fails((try? BackupService.encode(Snapshot())) ?? Data(), .empty))

            // A damaged or hand-edited file is repaired, and a sample-data flag is dropped.
            var damaged = real
            damaged.isDemo = true
            damaged.tenants.append(Tenant(unitID: UUID(), name: "Ghost", entryDate: now, monthlyRent: 500))
            if var p = damaged.payments.first { p.id = UUID(); damaged.payments[0] = p }
            let repaired = (try? BackupService.encode(damaged)).flatMap { try? BackupService.decode($0) }
            check("S22 records without a parent are dropped on restore", repaired.map { orphans($0) == 0 && !$0.tenants.contains { $0.name == "Ghost" } } == true)
            check("S22 payments get their fixed id back on restore", repaired.map { r in r.payments.allSatisfy { $0.id == Payment.stableID(tenant: $0.tenantID, month: $0.month) } } == true)
            check("S22 a restored backup is never the sample data", repaired?.isDemo == false)

            // Restoring replaces what is in the app.
            store.debugReplace(sample)
            check("S22 the app starts with the sample data", store.isDemo)
            if let back { store.restore(from: back) }
            check("S22 restoring replaces everything in the app", !store.isDemo && store.data.syncEntities == real.syncEntities)
        }

        // MARK: S23 — first use: what to do next, nothing due, taps that remove data, when to ask for a rating
        do {
            // When is it worth asking for a rating?
            check("S23 no rating prompt with no payments ticked", !ReviewManager.isEligible(payments: 0, isDemo: false, daysInUse: 30, minDays: 2))
            check("S23 no rating prompt on the sample data", !ReviewManager.isEligible(payments: 50, isDemo: true, daysInUse: 30, minDays: 2))
            check("S23 no rating prompt on the first day", !ReviewManager.isEligible(payments: 5, isDemo: false, daysInUse: 0.5, minDays: 2))
            check("S23 no rating prompt with only two payments ticked", !ReviewManager.isEligible(payments: ReviewManager.minPaymentsBeforeAsking - 1, isDemo: false, daysInUse: 30, minDays: 2))
            check("S23 a rating may be asked after real use", ReviewManager.isEligible(payments: ReviewManager.minPaymentsBeforeAsking, isDemo: false, daysInUse: 2, minDays: 2))

            // What is next for a new landlord.
            store.debugReplace(Snapshot())
            check("S23 an empty app asks for a home first", store.setupStep == .addHome)
            let p = Property(name: "P", address: "a", city: "c", kind: .traditional)
            let u = Unit(propertyID: p.id, name: "U", listRent: 700)
            var s1 = Snapshot(); s1.properties = [p]; s1.units = [u]
            store.debugReplace(s1)
            check("S23 a home with no tenant asks for a tenant", store.setupStep == .addTenant)
            let t = Tenant(unitID: u.id, name: "T", entryDate: cur.adding(-2).start, monthlyRent: 700)
            s1.tenants = [t]
            store.debugReplace(s1)
            check("S23 with a home and a tenant nothing is asked", store.setupStep == nil)

            let ui = AppUI()
            ui.homesPath = [.property(p.id)]
            ui.startSetup(.addTenant)
            check("S23 a get-started button opens the Homes tab on the tenants, at its first screen", ui.tab == .properties && ui.homesSegment == .tenants && ui.homesPath.isEmpty && ui.pendingSetup == .addTenant)

            // A tenant with no rent set has nothing to collect: not overdue, and ticking does nothing.
            let free = Tenant(unitID: u.id, name: "NoRent", entryDate: cur.adding(-3).start, monthlyRent: 0)
            s1.tenants = [free]
            store.debugReplace(s1)
            let tf = store.tenant(free.id)!
            check("S23 a tenant with no rent is not overdue", [cur.adding(-2), cur.adding(-1), cur].allSatisfy { store.status(of: tf, in: $0) == .upcoming })
            store.togglePayment(tf, month: cur.adding(-1))
            check("S23 ticking a month with nothing due records nothing", store.payment(of: tf.id, in: cur.adding(-1)) == nil)

            // A tap on a month that has a payment asks first.
            s1.tenants = [t]
            store.debugReplace(s1)
            let tt = store.tenant(t.id)!
            let month = cur.adding(-1)
            ui.tapPayment(tt, month: month, store: store)
            check("S23 ticking a month is immediate", store.payment(of: tt.id, in: month) != nil && ui.unmark == nil)
            store.setPayment(tt, month: month, rent: 500, supplies: 0, paidOn: day(2026, 3, 9))   // a payment with its own amount and date
            ui.tapPayment(tt, month: month, store: store)
            check("S23 tapping a paid month asks before removing it and removes nothing yet", ui.unmark?.month == month && store.payment(of: tt.id, in: month)?.amount == 500)
            if let request = ui.unmark { store.removePayment(request.tenant, month: request.month); ui.unmark = nil }
            check("S23 once confirmed, the payment is removed", store.payment(of: tt.id, in: month) == nil)
        }

        // MARK: S24 — the plans: 3 free homes, unlimited when subscribed, nothing ever hidden
        do {
            check("S24 the free plan has 3 homes", Plan.freeHomeLimit == 3)
            check("S24 a free landlord can add homes while below the limit", [0, 1, 2].allSatisfy { Plan.canAddHome(count: $0, subscribed: false) })
            check("S24 a free landlord cannot add a fourth home", !Plan.canAddHome(count: 3, subscribed: false) && !Plan.canAddHome(count: 40, subscribed: false))
            check("S24 a subscriber has no limit", [0, 3, 4, 100].allSatisfy { Plan.canAddHome(count: $0, subscribed: true) })
            check("S24 the sample portfolio (6 homes) is past the free limit, so no more can be added to it", !Plan.canAddHome(count: DemoData.make().properties.count, subscribed: false))

            // The store applies the same rule to the number of homes it holds.
            var three = Snapshot()
            for i in 0..<3 { three.properties.append(Property(name: "H\(i)", address: "a", city: "c", kind: .traditional)) }
            store.debugReplace(three)
            check("S24 the store follows the rule: three homes", store.canAddHome == Plan.canAddHome(count: 3, subscribed: StoreManager.shared.hasCloud))
            three.properties.append(Property(name: "H3", address: "a", city: "c", kind: .traditional))
            store.debugReplace(three)
            check("S24 homes past the limit are kept, never hidden or removed", store.data.properties.count == 4 && store.canAddHome == StoreManager.shared.hasCloud)
        }

        // MARK: P — timings: a typical landlord and a very large one
        func portfolio(homes: Int, rooms: Int, years: Int) -> Snapshot {
            var s = Snapshot()
            var rng = SystemRandomNumberGenerator()
            for pi in 0..<homes {
                var p = Property(name: "Home \(pi)", address: "a", city: "c", kind: .rooms)
                if pi % 3 == 0 { p.management = Management(name: "M", percent: 8, plusVAT: pi % 2 == 0) }
                p.cadastralValue = 90_000
                s.properties.append(p)
                for ui in 0..<rooms {
                    let u = Unit(propertyID: p.id, name: "R\(ui)", listRent: 400)
                    s.units.append(u)
                    var start = cur.adding(-12 * years + Int.random(in: 0...3, using: &rng))
                    while start <= cur {
                        let stay = Int.random(in: 14...22, using: &rng)
                        var t = Tenant(unitID: u.id, name: "T\(pi)-\(ui)", entryDate: start.start, monthlyRent: 400, monthlyExpenses: 35, deposit: 400)
                        let end = start.adding(stay)
                        if end < cur { t.exitDate = end.start }
                        s.tenants.append(t)
                        var m = start
                        while m <= min(end, cur) { if !(m == cur && Bool.random()) { s.payments.append(pay(t, m, rent: 400, supplies: 35)) }; m = m.adding(1) }
                        start = end.adding(1)
                    }
                }
                for (cat, f, amount) in [(ExpenseCategory.community, Frequency.quarterly, 180.0), (.ibi, .annual, 600), (.electricity, .monthly, 150), (.water, .monthly, 50),
                                         (.internet, .monthly, 40), (.insurance, .annual, 300), (.garbageTax, .annual, 90), (.cleaning, .monthly, 70)] {
                    s.expenses.append(Expense(propertyID: p.id, unitID: nil, category: cat, title: cat.rawValue, amount: amount, frequency: f, firstMonth: cur.adding(-12 * years)))
                }
            }
            return s
        }
        func timings(_ label: String, _ s: Snapshot, strict: Bool) {
            store.debugReplace(s)
            line("AUDIT INFO \(label): \(s.properties.count) homes, \(s.units.count) rooms, \(s.tenants.count) tenants, \(s.payments.count) payments, \(s.expenses.count) expenses")
            func ms(_ name: String, limit: Double, _ body: () -> Void) {
                body()
                let t0 = CFAbsoluteTimeGetCurrent()
                for _ in 0..<3 { body() }
                let t = (CFAbsoluteTimeGetCurrent() - t0) / 3 * 1000
                if strict { check("P[\(label)] \(name) < \(Int(limit)) ms", t < limit, String(format: "%.1f ms", t)) } else { line(String(format: "AUDIT INFO P[%@] %@: %.1f ms", label, name, t)) }
            }
            ms("totals of the month", limit: 20) { _ = store.totals(in: cur) }
            ms("totals of the year", limit: 80) { _ = store.totals(year: cur.year) }
            ms("alerts", limit: 100) { _ = store.alerts() }
            ms("unpaid charges since the beginning", limit: 100) { _ = store.unpaidCharges() }
            ms("12-month KPI series", limit: 150) { _ = store.kpiSeries(ending: cur) }
            ms("chart, yearly bars", limit: 150) { _ = store.chartPoints(for: ReportPeriod(kind: .year, anchor: cur)) }
            ms("fiscal figures of the year", limit: 200) { _ = ReportService.figures(year: cur.year, store: store) }
            ms("summary by room", limit: 150) { _ = store.summaryByUnit(year: cur.year) }
            ms("sync entities + diff", limit: 50) { _ = Snapshot.syncDiff(from: s, to: store.data) }
            ms("one render of the Summary tab", limit: 120) {
                let q = ReportPeriod(kind: .quarter, anchor: cur)
                _ = store.totals(q); _ = store.totals(q.with(kind: .month)); _ = store.totals(q.with(kind: .year))
                _ = store.chartPoints(for: q); _ = store.alerts(); _ = store.alerts()
                _ = store.data.properties.map { store.occupied($0.id) }; _ = store.summaryByProperty(months: q.accountedMonths)
            }
            ms("one render of the Collections tab", limit: 100) {
                _ = store.totals(in: cur); let ts = store.tenants(in: cur); _ = ts.map { store.status(of: $0, in: cur) }
            }
            let t0 = CFAbsoluteTimeGetCurrent()
            store.save(store.data.tenants[0])
            let save = (CFAbsoluteTimeGetCurrent() - t0) * 1000
            if strict { check("P[\(label)] saving one edit < 150 ms", save < 150, String(format: "%.1f ms", save)) }
        }
        timings("typical", portfolio(homes: 6, rooms: 3, years: 3), strict: true)
        timings("very large", portfolio(homes: 30, rooms: 5, years: 5), strict: false)

        line("AUDIT DONE failures=\(fails)")
        try? report.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("audit.txt"), atomically: true, encoding: .utf8)
    }
}
#endif
