//
//  RentalStore.swift
//  Renting
//
//  Single source of truth: holds the snapshot, persists it as JSON in Application
//  Support (backed up by iCloud Backup, never uploaded) and answers every
//  aggregation the screens need (month, year, by property / room / tenant).
//

import Foundation
import Observation

struct Totals: Equatable {
    var expected = 0.0
    var collected = 0.0
    /// Part of `collected` that is rent; the rest is utilities charged on top.
    var rent = 0.0
    var expenses = 0.0
    var supplies: Double { collected - rent }
    var net: Double { collected - expenses }
    var pending: Double { max(0, expected - collected) }

    static func + (a: Totals, b: Totals) -> Totals {
        Totals(expected: a.expected + b.expected, collected: a.collected + b.collected, rent: a.rent + b.rent, expenses: a.expenses + b.expenses)
    }
}

enum CollectionStatus {
    case paid, partial, upcoming, overdue
}

struct SummaryRow: Identifiable {
    let id: UUID
    var title: String
    var subtitle: String
    var income: Double
    var expected: Double
    var expenses: Double
    var net: Double { income - expenses }
}

@MainActor
@Observable
final class RentalStore {
    static let shared = RentalStore()

    private(set) var data: Snapshot
    private let fileURL: URL
    /// Name of the copy kept when the data file could not be read at launch (shown once).
    private(set) var recoveredBackup: String?
    /// Set when the last write to disk failed: the edits are only in memory until one succeeds.
    private(set) var saveError: String?
    /// Counts every change to the data: lets derived results (the alerts) be reused until it changes.
    @ObservationIgnored private(set) var dataVersion = 0
    @ObservationIgnored var alertsMemo: (key: AlertsMemoKey, value: [RentAlert])?
    /// Lookups by id, rebuilt on every change: without them every screen scans the whole list for each row.
    @ObservationIgnored private var propertyIndex: [UUID: Property] = [:]
    @ObservationIgnored private var unitIndex: [UUID: Unit] = [:]
    @ObservationIgnored private var tenantIndex: [UUID: Tenant] = [:]
    @ObservationIgnored private var unitsByProperty: [UUID: [Unit]] = [:]
    @ObservationIgnored private var tenantsByUnit: [UUID: [Tenant]] = [:]
    /// `payments` indexed by tenant and month: the lookup behind every screen.
    @ObservationIgnored private var paymentIndex: [PaymentKey: Payment] = [:]
    /// Told about every change the landlord makes (not those that arrive from iCloud), with the
    /// data before and after: this is how iCloud sync learns what to upload.
    @ObservationIgnored var syncObserver: ((_ old: Snapshot, _ new: Snapshot) -> Void)?

    private struct PaymentKey: Hashable { let tenant: UUID; let month: MonthKey }

    /// What the alerts depend on: the data, the day, the rules, and the language and currency of their texts.
    struct AlertsMemoKey: Hashable {
        let version: Int
        let day: Date
        let config: Int
        let instance: ObjectIdentifier
        let text: String
    }

    /// Day of the month after which an unpaid current-month rent counts as overdue (alert rule).
    static var dueDay: Int { Int(AlertConfig.shared.rule(.lateRent).param) }

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appendingPathComponent("renting.json")
        data = Snapshot()
        if let raw = try? Data(contentsOf: fileURL) {
            if let snap = try? JSONDecoder().decode(Snapshot.self, from: raw) {
                data = snap
            } else {
                // The file exists but cannot be read (damaged, or written by a newer version).
                // Starting empty is fine; overwriting it with the first edit is not: keep it aside.
                let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
                let name = "renting-unreadable-\(stamp).json"
                if (try? FileManager.default.moveItem(at: fileURL, to: base.appendingPathComponent(name))) != nil { recoveredBackup = name }
            }
        }
        data.normalizePayments()
        reindex()
    }

    func dismissRecoveryNotice() { recoveredBackup = nil }

    private func reindex() {
        propertyIndex = Dictionary(data.properties.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        unitIndex = Dictionary(data.units.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        tenantIndex = Dictionary(data.tenants.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        unitsByProperty = Dictionary(grouping: data.units, by: \.propertyID)
        tenantsByUnit = Dictionary(grouping: data.tenants, by: \.unitID)
        paymentIndex = Dictionary(data.payments.map { (PaymentKey(tenant: $0.tenantID, month: $0.month), $0) }, uniquingKeysWith: { a, _ in a })
        dataVersion += 1
    }

    var isEmpty: Bool { data.properties.isEmpty }

    /// What a new landlord has to do next: add a home, then a tenant. `nil` once both exist.
    var setupStep: SetupStep? {
        observeData()
        if data.properties.isEmpty { return .addHome }
        return data.tenants.isEmpty ? .addTenant : nil
    }
    var isDemo: Bool { data.isDemo }

    private func commit(fromCloud: Bool = false, _ change: (inout Snapshot) -> Void) {
        let before = data
        change(&data)
        reindex()
        do {
            try JSONEncoder().encode(data).write(to: fileURL, options: .atomic)
            if saveError != nil { saveError = nil }
        } catch {
            saveError = error.localizedDescription
        }
        if !fromCloud { syncObserver?(before, data) }
        WidgetBridge.refresh()
    }

    #if DEBUG
    /// Tests only: replaces the data (without telling iCloud sync).
    func debugReplace(_ snapshot: Snapshot) { commit(fromCloud: true) { $0 = snapshot } }
    #endif

    /// Drops records whose home, room or tenant is gone (see `Snapshot.pruneOrphans`). Local only:
    /// the next sync notices the difference and removes them from iCloud too.
    func pruneOrphansFromCloud() {
        var probe = data
        probe.pruneOrphans()
        guard probe.recordCount != data.recordCount else { return }
        commit(fromCloud: true) { $0.pruneOrphans() }
    }

    /// Applies what iCloud sent: it is saved like any change but never uploaded back.
    func applyFromCloud(_ upserts: [SyncEntity], deleting names: [String]) {
        commit(fromCloud: true) { $0.apply(upserts, deleting: names) }
    }

    // MARK: Lookup

    /// The indexes below are not observable themselves, so every lookup through them registers
    /// the dependency on `data` by hand: a view that only asks "is this month paid?" must
    /// redraw when the payment is ticked or un-ticked.
    func observeData() { access(keyPath: \.data) }

    func property(_ id: UUID) -> Property? { observeData(); return propertyIndex[id] }
    func unit(_ id: UUID) -> Unit? { observeData(); return unitIndex[id] }
    func tenant(_ id: UUID) -> Tenant? { observeData(); return tenantIndex[id] }

    func units(of property: UUID) -> [Unit] { observeData(); return unitsByProperty[property] ?? [] }
    func tenants(of unit: UUID) -> [Tenant] {
        observeData()
        return (tenantsByUnit[unit] ?? []).sorted { $0.entryDate > $1.entryDate }
    }

    func propertyID(ofUnit unit: UUID) -> UUID? { self.unit(unit)?.propertyID }
    func propertyID(ofTenant tenant: Tenant) -> UUID? { propertyID(ofUnit: tenant.unitID) }

    /// The tenant living in a unit today, if any.
    func currentTenant(of unit: UUID, now: Date = Date()) -> Tenant? {
        observeData()
        return (tenantsByUnit[unit] ?? []).first { $0.entryDate <= now && ($0.exitDate.map { $0 > now } ?? true) }
    }

    func unitLabel(_ tenant: Tenant) -> String {
        guard let u = unit(tenant.unitID), let p = property(u.propertyID) else { return "" }
        return p.kind == .rooms ? "\(p.name) · \(u.name)" : p.name
    }

    // MARK: Occupancy

    func occupied(_ property: UUID) -> (occupied: Int, total: Int) {
        let us = units(of: property)
        return (us.filter { currentTenant(of: $0.id) != nil }.count, us.count)
    }

    var occupancy: (occupied: Int, total: Int) {
        data.properties.reduce((0, 0)) { acc, p in
            let o = occupied(p.id)
            return (acc.0 + o.occupied, acc.1 + o.total)
        }
    }

    // MARK: Rent collection

    /// Tenants living in a unit during `month`, in no particular order (for sums).
    func activeTenants(in month: MonthKey, property: UUID? = nil) -> [Tenant] {
        data.tenants.filter { $0.isActive(in: month) && (property == nil || propertyID(ofTenant: $0) == property) }
    }

    /// The same, sorted by home and room (for lists).
    func tenants(in month: MonthKey, property: UUID? = nil) -> [Tenant] {
        activeTenants(in: month, property: property).sorted { unitLabel($0) < unitLabel($1) }
    }

    func payment(of tenant: UUID, in month: MonthKey) -> Payment? {
        observeData()
        return paymentIndex[PaymentKey(tenant: tenant, month: month)]
    }

    /// Splits a payment into rent and utilities. Payments saved without the split
    /// count as rent first.
    func split(_ p: Payment) -> (rent: Double, supplies: Double) {
        if let supplies = p.supplies { return (max(0, p.amount - supplies), supplies) }
        let rent = min(p.amount, tenant(p.tenantID)?.rent(in: p.month) ?? p.amount)
        return (rent, p.amount - rent)
    }

    /// Rent (without utilities) collected in `month`: the base of the manager fee and
    /// of the fiscal report.
    func rentCollected(in month: MonthKey, property: UUID? = nil) -> Double {
        activeTenants(in: month, property: property).reduce(0) { $0 + (payment(of: $1.id, in: month).map { split($0).rent } ?? 0) }
    }

    /// Rent collected in `month` for every home at once: one pass instead of one per home.
    func rentCollectedByProperty(in month: MonthKey) -> [UUID: Double] {
        var out: [UUID: Double] = [:]
        for t in data.tenants where t.isActive(in: month) {
            guard let p = payment(of: t.id, in: month), let home = propertyID(ofTenant: t) else { continue }
            out[home, default: 0] += split(p).rent
        }
        return out
    }

    /// What was due from a tenant for a month. Once a payment is recorded it keeps what was due
    /// at that moment, so a later rent increase does not rewrite the months already settled.
    func rentDue(of tenant: Tenant, in month: MonthKey) -> Double { payment(of: tenant.id, in: month)?.rentDue ?? tenant.rent(in: month) }
    func suppliesDue(of tenant: Tenant, in month: MonthKey) -> Double { payment(of: tenant.id, in: month)?.suppliesDue ?? tenant.monthlyExpenses }
    func due(of tenant: Tenant, in month: MonthKey) -> Double { rentDue(of: tenant, in: month) + suppliesDue(of: tenant, in: month) }

    /// Rent that fell due in `month` and was not collected (overdue or partial only).
    func unpaidRent(of tenant: Tenant, in month: MonthKey, now: Date = Date()) -> Double {
        let st = status(of: tenant, in: month, now: now)
        guard st == .overdue || st == .partial else { return 0 }
        let paid = payment(of: tenant.id, in: month).map { split($0).rent } ?? 0
        return max(0, rentDue(of: tenant, in: month) - paid)
    }

    func status(of tenant: Tenant, in month: MonthKey, now: Date = Date()) -> CollectionStatus {
        if let p = payment(of: tenant.id, in: month) {
            return p.amount + 0.005 >= (p.rentDue ?? tenant.rent(in: month)) + (p.suppliesDue ?? tenant.monthlyExpenses) ? .paid : .partial
        }
        // Nothing is due (no rent has been set): it is not overdue, there is just nothing to collect yet.
        if due(of: tenant, in: month) <= 0.005 { return .upcoming }
        let current = MonthKey(now)
        if month < current { return .overdue }
        if month == current, Calendar.current.component(.day, from: now) > Self.dueDay { return .overdue }
        return .upcoming
    }

    /// Ticks (or un-ticks) a month's collection. Un-ticking removes the payment.
    func togglePayment(_ tenant: Tenant, month: MonthKey) {
        if let existing = payment(of: tenant.id, in: month) {
            commit { $0.payments.removeAll { $0.id == existing.id } }
        } else if due(of: tenant, in: month) > 0.005 {
            setPayment(tenant, month: month, rent: tenant.rent(in: month), supplies: tenant.monthlyExpenses)
        }
    }

    func setPayment(_ tenant: Tenant, month: MonthKey, rent: Double, supplies: Double, paidOn: Date? = nil) {
        let now = Date()
        let date = paidOn ?? min(now, Calendar.current.date(byAdding: .day, value: 4, to: month.start) ?? now)
        commit {
            $0.payments.removeAll { $0.tenantID == tenant.id && $0.month == month }
            $0.payments.append(Payment(id: Payment.stableID(tenant: tenant.id, month: month), tenantID: tenant.id, month: month,
                                       amount: rent + supplies, paidOn: date, supplies: supplies,
                                       rentDue: tenant.rent(in: month), suppliesDue: tenant.monthlyExpenses))
        }
    }

    /// Every month of a tenancy up to the current one, for the payment calendar.
    func tenancyMonths(_ tenant: Tenant, now: Date = Date()) -> [MonthKey] {
        let first = MonthKey(tenant.entryDate)
        let last = min(tenant.exitDate.map { MonthKey($0) } ?? MonthKey(now), MonthKey(now))
        guard first <= last else { return [] }
        return (0...last.months(since: first)).map { first.adding($0) }
    }

    func removePayment(_ tenant: Tenant, month: MonthKey) {
        commit { $0.payments.removeAll { $0.tenantID == tenant.id && $0.month == month } }
    }

    // MARK: Totals

    func expenseTotal(in month: MonthKey, property: UUID? = nil) -> Double {
        charges(in: month, property: property).reduce(0) { $0 + $1.amount }
    }

    func totals(in month: MonthKey, property: UUID? = nil) -> Totals {
        let ts = activeTenants(in: month, property: property)
        var t = Totals()
        t.expected = ts.reduce(0) { $0 + due(of: $1, in: month) }
        for tenant in ts {
            guard let p = payment(of: tenant.id, in: month) else { continue }
            t.collected += p.amount
            t.rent += split(p).rent
        }
        t.expenses = expenseTotal(in: month, property: property)
        return t
    }

    func totals(year: Int, property: UUID? = nil) -> Totals {
        totals(months: MonthKey.months(of: year), property: property)
    }

    func series(year: Int, property: UUID? = nil) -> [(month: MonthKey, totals: Totals)] {
        MonthKey.months(of: year).map { ($0, totals(in: $0, property: property)) }
    }

    /// Years that have any activity, newest first (always includes the current year).
    var years: [Int] {
        var set: Set<Int> = [MonthKey.current.year]
        data.tenants.forEach { set.insert(MonthKey($0.entryDate).year) }
        data.payments.forEach { set.insert($0.month.year) }
        data.expenses.forEach { set.insert($0.firstMonth.year) }
        return set.sorted(by: >)
    }

    // MARK: Yearly summaries (the period versions are in `Period.swift`)

    func summaryByProperty(year: Int) -> [SummaryRow] { summaryByProperty(months: MonthKey.months(of: year)) }
    func summaryByUnit(year: Int) -> [SummaryRow] { summaryByUnit(months: MonthKey.months(of: year)) }
    func summaryByTenant(year: Int) -> [SummaryRow] { summaryByTenant(months: MonthKey.months(of: year)) }

    // MARK: Expenses

    func expenseBreakdown(year: Int, property: UUID? = nil) -> [(category: ExpenseCategory, amount: Double)] {
        expenseBreakdown(months: MonthKey.months(of: year), property: property)
    }

    /// The manager's fee for `month`: a percentage of the rent collected, never of the
    /// utilities paid on top.
    func managementFee(in month: MonthKey, property: UUID) -> Double {
        guard let m = self.property(property)?.management, m.percent > 0 else { return 0 }
        return (rentCollected(in: month, property: property) * m.rate * 100).rounded() / 100
    }

    func managementTitle(_ property: Property) -> String {
        guard let m = property.management else { return "" }
        let name = m.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? L("mgmt.fee") : name
    }

    /// "8 % + VAT of the rent".
    func managementTerms(_ m: Management) -> String {
        let pct = m.percent.formatted(.number.precision(.fractionLength(0...2)).locale(AppLanguage.shared.locale))
        return L(m.plusVAT ? "mgmt.terms_vat" : "mgmt.terms", pct)
    }

    /// Everything falling due in `month`: recorded expenses and manager fees.
    func charges(in month: MonthKey, property: UUID? = nil) -> [Charge] {
        var out: [Charge] = []
        var collected: [UUID: Double]?
        for e in data.expenses where property == nil || e.propertyID == property {
            let amount = e.amount(in: month)
            guard amount > 0 else { continue }
            out.append(Charge(source: .expense(e.id), month: month, propertyID: e.propertyID, category: e.category,
                              title: e.title, amount: amount, isPaid: e.paidMonths.contains(month),
                              planned: e.plannedAmount(in: month), isActual: e.hasActual(in: month)))
        }
        for p in data.properties where property == nil || p.id == property {
            guard let m = p.management, m.percent > 0 else { continue }
            if collected == nil { collected = rentCollectedByProperty(in: month) }
            let fee = ((collected?[p.id] ?? 0) * m.rate * 100).rounded() / 100
            guard fee > 0 else { continue }
            out.append(Charge(source: .management(p.id), month: month, propertyID: p.id, category: .manager,
                              title: managementTitle(p), amount: fee, isPaid: m.paidMonths.contains(month), planned: fee))
        }
        return out
    }

    /// Charges already due (up to the current month) and not paid yet, oldest first.
    func unpaidCharges(property: UUID? = nil, now: Date = Date()) -> [Charge] {
        let current = MonthKey(now)
        let starts = data.expenses.map(\.firstMonth) + data.tenants.map { MonthKey($0.entryDate) }
        guard var m = starts.min() else { return [] }
        var out: [Charge] = []
        while m <= current {
            out += charges(in: m, property: property).filter { !$0.isPaid }
            m = m.adding(1)
        }
        return out
    }

    func setPaid(_ charges: [Charge], _ paid: Bool) {
        commit { s in
            for c in charges {
                switch c.source {
                case .expense(let id):
                    guard let i = s.expenses.firstIndex(where: { $0.id == id }) else { continue }
                    if paid { s.expenses[i].paidMonths.insert(c.month) } else { s.expenses[i].paidMonths.remove(c.month) }
                case .management(let id):
                    guard let i = s.properties.firstIndex(where: { $0.id == id }), s.properties[i].management != nil else { continue }
                    if paid { s.properties[i].management?.paidMonths.insert(c.month) } else { s.properties[i].management?.paidMonths.remove(c.month) }
                }
            }
        }
    }

    func togglePaid(_ charge: Charge) { setPaid([charge], !charge.isPaid) }

    /// Records the real bill of a month (`nil`, or the planned amount, goes back to the plan).
    func setActual(_ amount: Double?, expense id: UUID, month: MonthKey) {
        commit { s in
            guard let i = s.expenses.firstIndex(where: { $0.id == id }) else { return }
            var actuals = s.expenses[i].actuals ?? [:]
            if let amount, abs(amount - s.expenses[i].plannedAmount(in: month)) > 0.004 { actuals[month.id] = amount } else { actuals[month.id] = nil }
            s.expenses[i].actuals = actuals.isEmpty ? nil : actuals
        }
    }

    func expense(_ id: UUID) -> Expense? { data.expenses.first { $0.id == id } }

    /// What tenants paid for utilities during `year` against the utility bills of the
    /// same homes: shows whether the flat amount charged covers the real cost.
    func suppliesBalance(year: Int, property: UUID? = nil) -> (charged: Double, bills: Double) {
        let total = totals(year: year, property: property)
        let bills = expenseBreakdown(year: year, property: property).filter { $0.category.isUtility }.reduce(0) { $0 + $1.amount }
        return (total.supplies, bills)
    }

    // MARK: Fiscal (Spanish income tax)

    /// The reduction applied to a tenant's contract: the one chosen, or automatically
    /// none for seasonal lets, 60 % before 26 May 2023 and 50 % afterwards.
    func reduction(for tenant: Tenant) -> RentReduction {
        tenant.reduction ?? automaticReduction(for: tenant)
    }

    func automaticReduction(for tenant: Tenant) -> RentReduction {
        if !isHousingLease(tenant) { return .none }
        return tenant.entryDate < RentReduction.newLawDate ? .legacy60 : .general50
    }

    nonisolated static func days(in year: Int) -> Int {
        let cal = Calendar.current
        guard let a = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
              let b = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else { return 365 }
        return cal.dateComponents([.day], from: a, to: b).day ?? 365
    }

    /// Days of `year` in which some tenant lived in the unit (entry and exit days included).
    /// Tenants with no exit date count as staying until the end of the year.
    func rentedDays(unit: UUID, year: Int) -> Int {
        let cal = Calendar.current
        guard let start = cal.date(from: DateComponents(year: year, month: 1, day: 1)) else { return 0 }
        let total = Self.days(in: year)
        func offset(_ date: Date) -> Int { cal.dateComponents([.day], from: start, to: cal.startOfDay(for: date)).day ?? 0 }
        var days = Set<Int>()
        for t in tenantsByUnit[unit] ?? [] {
            let lo = max(0, offset(t.entryDate))
            let hi = min(total - 1, t.exitDate.map(offset) ?? total - 1)
            if lo <= hi { days.formUnion(lo...hi) }
        }
        return days.count
    }

    func rentedShare(unit: UUID, year: Int) -> Double {
        Double(rentedDays(unit: unit, year: year)) / Double(Self.days(in: year))
    }

    /// Share of `year` the home was let, each room counting equally: 1 = every room all year.
    func rentedShare(property: UUID, year: Int) -> Double {
        let us = units(of: property)
        guard !us.isEmpty else { return 0 }
        return us.reduce(0) { $0 + rentedShare(unit: $1.id, year: year) } / Double(us.count)
    }

    // MARK: Fiscal settings

    func isDeductible(_ category: ExpenseCategory) -> Bool {
        data.deductible.map { $0.contains(category) } ?? category.deductibleByDefault
    }

    func setDeductible(_ category: ExpenseCategory, _ on: Bool) {
        commit { s in
            var set = s.deductible ?? Set(ExpenseCategory.allCases.filter(\.deductibleByDefault))
            if on { set.insert(category) } else { set.remove(category) }
            s.deductible = set
        }
    }

    /// Next month (from the current one) in which an expense falls due, with its amount.
    func nextDue(_ e: Expense, from month: MonthKey = .current) -> (month: MonthKey, amount: Double)? {
        for i in 0..<24 {
            let m = month.adding(i)
            let a = e.amount(in: m)
            if a > 0 { return (m, a) }
        }
        return nil
    }

    // MARK: CRUD

    func save(_ property: Property, units newUnits: [Unit]? = nil) {
        commit { s in
            if let i = s.properties.firstIndex(where: { $0.id == property.id }) { s.properties[i] = property } else { s.properties.append(property) }
            if let newUnits {
                let keep = Set(newUnits.map(\.id))
                s.units.removeAll { $0.propertyID == property.id && !keep.contains($0.id) }
                for u in newUnits {
                    if let i = s.units.firstIndex(where: { $0.id == u.id }) { s.units[i] = u } else { s.units.append(u) }
                }
            }
        }
    }

    func save(_ unit: Unit) {
        commit { s in
            if let i = s.units.firstIndex(where: { $0.id == unit.id }) { s.units[i] = unit } else { s.units.append(unit) }
        }
    }

    func deleteProperty(_ id: UUID) {
        commit { s in
            let unitIDs = Set(s.units.filter { $0.propertyID == id }.map(\.id))
            let tenantIDs = Set(s.tenants.filter { unitIDs.contains($0.unitID) }.map(\.id))
            s.payments.removeAll { tenantIDs.contains($0.tenantID) }
            s.tenants.removeAll { tenantIDs.contains($0.id) }
            s.expenses.removeAll { $0.propertyID == id }
            s.units.removeAll { unitIDs.contains($0.id) }
            s.properties.removeAll { $0.id == id }
        }
    }

    func deleteUnit(_ id: UUID) {
        commit { s in
            let tenantIDs = Set(s.tenants.filter { $0.unitID == id }.map(\.id))
            s.payments.removeAll { tenantIDs.contains($0.tenantID) }
            s.tenants.removeAll { tenantIDs.contains($0.id) }
            s.expenses.removeAll { $0.unitID == id }
            s.units.removeAll { $0.id == id }
        }
    }

    func save(_ tenant: Tenant) {
        commit { s in
            if let i = s.tenants.firstIndex(where: { $0.id == tenant.id }) { s.tenants[i] = tenant } else { s.tenants.append(tenant) }
        }
    }

    func deleteTenant(_ id: UUID) {
        commit { s in
            s.payments.removeAll { $0.tenantID == id }
            s.tenants.removeAll { $0.id == id }
        }
    }

    func save(_ expense: Expense) {
        commit { s in
            if let i = s.expenses.firstIndex(where: { $0.id == expense.id }) { s.expenses[i] = expense } else { s.expenses.append(expense) }
        }
    }

    func deleteExpense(_ id: UUID) { commit { $0.expenses.removeAll { $0.id == id } } }

    // MARK: Demo / reset

    /// Replaces the data with the sample portfolio. With `asReal` the data is NOT flagged as
    /// sample data, so that iCloud sync (which never uploads sample data) can be tested with a
    /// full portfolio. Ids are random on every load: load it on ONE device only and let the
    /// others download it, or the portfolio ends up twice.
    func loadDemo(asReal: Bool = false) {
        commit { $0 = DemoData.make(); $0.isDemo = !asReal }
    }

    func eraseAll() {
        commit { $0 = Snapshot() }
    }

    /// Replaces everything with the data of a backup (see `BackupService`). It is saved like any
    /// change, so iCloud sync, if it is on, follows.
    func restore(from snapshot: Snapshot) {
        commit { $0 = snapshot }
    }
}
