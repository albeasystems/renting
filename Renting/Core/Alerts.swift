//
//  Alerts.swift
//  Renting
//
//  Evaluates every alert rule (`AlertRules.swift`) against the data and builds the list the
//  landlord sees, most urgent first; and turns the rules that notify into scheduled local
//  notifications (Pro). Nothing is stored: alerts are derived, so they disappear on their
//  own once the cause is solved.
//

import Foundation
import SwiftUI
import UserNotifications

struct RentAlert: Identifiable {
    let id: String
    let kind: AlertRuleKind
    var severity: AlertSeverity
    let title: String
    let detail: String
    var date: Date?

    var icon: String { kind.icon }
    var color: Color { kind.color }
}

extension RentalStore {

    /// Everything that needs the landlord's attention, most urgent first. The Summary tab asks
    /// for it several times per screen, so the result is reused until the data, the day, the
    /// rules or the language change.
    func alerts(now: Date = Date(), config: AlertConfig = .shared) -> [RentAlert] {
        observeData()   // a reused result must still redraw the view when the data changes
        let key = AlertsMemoKey(version: dataVersion, day: Calendar.current.startOfDay(for: now), config: config.revision,
                                instance: ObjectIdentifier(config), text: "\(AppLanguage.shared.code)|\(AppCurrency.shared.code)")
        if let memo = alertsMemo, memo.key == key { return memo.value }
        let value = buildAlerts(now: now, config: config)
        alertsMemo = (key, value)
        return value
    }

    private func buildAlerts(now: Date, config: AlertConfig) -> [RentAlert] {
        var out: [RentAlert] = []
        let cal = Calendar.current
        let current = MonthKey(now)
        func param(_ kind: AlertRuleKind) -> Double { config.rule(kind).param }
        func add(_ kind: AlertRuleKind, _ key: String, _ severity: AlertSeverity, _ title: String, _ detail: String, _ date: Date?) {
            out.append(RentAlert(id: "\(kind.rawValue).\(key)", kind: kind, severity: severity, title: title, detail: detail, date: date))
        }

        // Rent not paid after the configured day, and partial payments.
        if config.isOn(.lateRent) {
            for t in data.tenants {
                for m in (0...6).map({ current.adding(-$0) }) where t.isActive(in: m) {
                    let st = status(of: t, in: m, now: now)
                    guard st == .overdue || st == .partial else { continue }
                    let owed = due(of: t, in: m) - (payment(of: t.id, in: m)?.amount ?? 0)
                    guard owed > 0.5 else { continue }
                    let day = Int(param(.lateRent))
                    let title = m == current ? L("alert.late_current", t.name, day) : L("alert.overdue", t.name, m.title())
                    add(.lateRent, "\(t.id)\(m.id)", .high, title, "\(unitLabel(t)) · \(owed.moneyExact)", m.start)
                }
            }
        }

        // Rent still to come in this month (those not yet late).
        if config.isOn(.expectedRent) {
            let waiting = tenants(in: current).filter { status(of: $0, in: current, now: now) == .upcoming }
            if !waiting.isEmpty {
                let amount = waiting.reduce(0) { $0 + $1.monthlyTotal(in: current) }
                let total = totals(in: current)
                add(.expectedRent, "\(current.id)", .info, L("alert.expected", amount.moneyExact, waiting.count),
                    L("alert.expected.detail", total.collected.money, total.expected.money, Self.dueDay), current.start)
            }
        }

        // Expenses unpaid from the last three months.
        if config.isOn(.unpaidExpense) {
            for c in unpaidCharges(now: now) where c.month < current && c.month >= current.adding(-3) {
                add(.unpaidExpense, c.id, .high, L("alert.expense_unpaid", c.title, c.month.title()),
                    "\(property(c.propertyID)?.name ?? "") · \(c.amount.moneyExact)", c.month.start)
            }
        }

        // Non-monthly expenses due this month, or next month once it is within the notice period.
        if config.isOn(.upcomingExpense) {
            let lead = Int(param(.upcomingExpense))
            for e in data.expenses where e.frequency != .monthly {
                for m in [current, current.adding(1)] where e.amount(in: m) > 0 && !e.paidMonths.contains(m) {
                    if m > current, (cal.dateComponents([.day], from: cal.startOfDay(for: now), to: m.start).day ?? 99) > lead { continue }
                    add(.upcomingExpense, "\(e.id)\(m.id)", m == current ? .normal : .info, L("alert.expense", e.title, m.title()),
                        "\(property(e.propertyID)?.name ?? "") · \(e.amount(in: m).moneyExact)", m.start)
                }
            }
        }

        // A utility bill much higher than the previous ones.
        if config.isOn(.utilityIncrease) {
            for jump in utilityIncreases(threshold: param(.utilityIncrease), now: now) {
                add(.utilityIncrease, "\(jump.expense.id)\(jump.month.id)", .normal,
                    L("alert.utility_up", jump.expense.title, Int(jump.percent.rounded()), jump.month.title()),
                    L("alert.utility_up.detail", property(jump.expense.propertyID)?.name ?? "", jump.amount.moneyExact, jump.average.moneyExact), jump.month.start)
            }
        }

        // Tenants pay less for utilities than the bills cost.
        if config.isOn(.suppliesGap) {
            for gap in suppliesGaps(threshold: param(.suppliesGap), now: now) {
                add(.suppliesGap, "\(gap.property.id)\(gap.month.id)", .normal,
                    L("alert.supplies_gap", gap.property.name, gap.month.title()),
                    L("alert.supplies_gap.detail", gap.charged.moneyExact, gap.bills.moneyExact, (gap.bills - gap.charged).moneyExact), gap.month.start)
            }
        }

        // Homes and rooms empty for longer than the limit.
        if config.isOn(.vacancy) {
            for v in vacancies(minDays: Int(param(.vacancy)), now: now) {
                let name = property(v.unit.propertyID).map { $0.kind == .rooms ? "\($0.name) · \(v.unit.name)" : $0.name } ?? v.unit.name
                add(.vacancy, "\(v.unit.id)", .normal, L("alert.vacant", name, v.days),
                    L("alert.vacant.detail", v.lost.moneyExact), v.since)
            }
        }

        // Contracts ending soon.
        if config.isOn(.contractEnding) {
            let days = Int(param(.contractEnding))
            for t in data.tenants where t.isActive {
                guard let end = t.contractEnd,
                      let left = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: end)).day,
                      left >= 0, left <= days else { continue }
                // Months ahead it is a reminder; in the last month it needs action.
                add(.contractEnding, "\(t.id)", left <= 30 ? .high : .normal, L("alert.contract", t.name, end.short),
                    "\(unitLabel(t)) · \(L("alert.anniv_in", left))", end)
            }
        }

        // Deposits still held for tenants who already left.
        if config.isOn(.depositReturn) {
            for t in data.tenants where t.exitDate != nil && t.depositReturned == nil && t.deposit > 0 {
                add(.depositReturn, "\(t.id)", .normal, L("alert.deposit", t.name), "\(unitLabel(t)) · \(t.deposit.moneyExact)", t.exitDate)
            }
        }

        // Rent update: the anniversary is near (or just passed) and nothing was decided yet.
        if config.isOn(.rentUpdate) {
            for t in data.tenants {
                guard let r = pendingReview(for: t, now: now) else { continue }
                let when = r.daysToAnniversary >= 0 ? L("alert.anniv_in", r.daysToAnniversary) : L("alert.anniv_ago", -r.daysToAnniversary)
                add(.rentUpdate, "\(r.id)", .normal, L("alert.rent_update", t.name, r.anniversary.short), "\(unitLabel(t)) · \(when)", r.anniversary)
            }
        }

        // Fianza not marked as deposited: overdue (up to six months back, to avoid nagging about old
        // contracts) or due within a week.
        if config.isOn(.depositFiling) {
            for t in data.tenants {
                let detail = "\(unitLabel(t)) · \(t.deposit.moneyExact)"
                switch filingInfo(for: t, now: now).status {
                case .overdue(let d) where daysToDeadline(d, now: now) >= -180:
                    add(.depositFiling, "\(t.id)", .high, L("alert.filing_overdue", t.name, d.short), detail, d)
                case .pending(let d) where daysToDeadline(d, now: now) <= 7:
                    add(.depositFiling, "\(t.id)", .normal, L("alert.filing_due", t.name, d.short), detail, d)
                default:
                    break
                }
            }
        }

        return out.sorted { ($0.severity, $0.date ?? .distantFuture) < ($1.severity, $1.date ?? .distantFuture) }
    }

    var overdueCount: Int { alerts().filter { $0.kind == .lateRent }.count }

    // MARK: Detectors

    struct UtilityJump { let expense: Expense; let month: MonthKey; let amount: Double; let average: Double; let percent: Double }

    /// Utility bills whose latest amount is more than `threshold` % above the average of the
    /// previous (up to three) bills of the same expense. Only the last two months count.
    func utilityIncreases(threshold: Double, now: Date = Date()) -> [UtilityJump] {
        let current = MonthKey(now)
        var out: [UtilityJump] = []
        for e in data.expenses where e.category.isUtility && e.frequency != .once {
            let due = e.dueMonths(through: current)
            guard let latest = due.last, latest >= current.adding(-1), due.count >= 2 else { continue }
            let previous = due.dropLast().suffix(3).map { e.amount(in: $0) }
            let average = previous.reduce(0, +) / Double(previous.count)
            guard average > 0 else { continue }
            let percent = (e.amount(in: latest) / average - 1) * 100
            if percent >= threshold { out.append(UtilityJump(expense: e, month: latest, amount: e.amount(in: latest), average: average, percent: percent)) }
        }
        return out.sorted { $0.percent > $1.percent }
    }

    struct SuppliesGap { let property: Property; let month: MonthKey; let charged: Double; let bills: Double }

    /// Homes where, in the last closed month, the utility bills exceed what the tenants paid
    /// for utilities by more than `threshold` %. Homes that charge nothing for utilities are
    /// left out: their tenants probably pay the suppliers directly.
    func suppliesGaps(threshold: Double, now: Date = Date()) -> [SuppliesGap] {
        let month = MonthKey(now).adding(-1)
        return data.properties.compactMap { p in
            let charged = tenants(in: month, property: p.id).reduce(0.0) { $0 + (payment(of: $1.id, in: month).map { split($0).supplies } ?? 0) }
            let bills = charges(in: month, property: p.id).filter { $0.category.isUtility }.reduce(0) { $0 + $1.amount }
            guard charged > 0, bills > 0, bills > charged * (1 + threshold / 100) else { return nil }
            return SuppliesGap(property: p, month: month, charged: charged, bills: bills)
        }
    }

    struct Vacancy { let unit: Unit; let since: Date; let days: Int; let lost: Double }

    /// Units without a tenant for at least `minDays`, counted from the last tenant's exit
    /// (units never let have no start date, so they are not reported).
    func vacancies(minDays: Int, now: Date = Date()) -> [Vacancy] {
        let cal = Calendar.current
        return data.units.compactMap { u in
            guard currentTenant(of: u.id, now: now) == nil, let last = tenants(of: u.id).compactMap(\.exitDate).max() else { return nil }
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: now)).day ?? 0
            guard days >= minDays else { return nil }
            return Vacancy(unit: u, since: last, days: days, lost: u.listRent * Double(days) / 30)
        }.sorted { $0.days > $1.days }
    }
}

// MARK: - Local notifications (Pro)

struct PlannedNotification {
    let id: String
    let title: String
    let body: String
    let date: Date
}

@MainActor
enum AlertsManager {
    static let enabledKey = "alerts_enabled"
    private static let prefix = "renting.alert."
    /// iOS keeps at most 64 pending local notifications.
    private static let limit = 60

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }

    /// Asks for permission; returns whether notifications are allowed.
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Rebuilds every scheduled notification from the current data and rules. Cheap; call it
    /// on launch, when going to background and after the toggle or a rule changes.
    static func reschedule(store: RentalStore, isPro: Bool, config: AlertConfig = .shared) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        guard isPro, isEnabled, !store.isEmpty else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let cal = Calendar.current
        for p in plan(store: store, config: config, now: Date()).sorted(by: { $0.date < $1.date }).prefix(limit) {
            let content = UNMutableNotificationContent()
            content.title = p.title
            content.body = p.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: p.date), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: prefix + p.id, content: content, trigger: trigger))
        }
    }

    /// A notification in a few seconds, to check that they arrive.
    static func sendTest() async {
        let content = UNMutableNotificationContent()
        content.title = L("notif.test.title")
        content.body = L("notif.test.body")
        content.sound = .default
        _ = try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: prefix + "test", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 4, repeats: false)))
    }

    /// Every notification the rules ask for in the coming months. Pure: it only reads the data.
    static func plan(store: RentalStore, config: AlertConfig, now: Date) -> [PlannedNotification] {
        let cal = Calendar.current
        let current = MonthKey(now)
        var out: [PlannedNotification] = []

        func at(_ date: Date) -> Date? {
            cal.date(bySettingHour: config.minutes / 60, minute: config.minutes % 60, second: 0, of: date)
        }
        func plan(_ id: String, _ title: String, _ body: String, on date: Date?) {
            guard let when = date.flatMap(at), when > now else { return }
            out.append(PlannedNotification(id: id, title: title, body: body, date: when))
        }
        func day(_ month: MonthKey, _ d: Int) -> Date? { cal.date(from: DateComponents(year: month.year, month: month.month, day: d)) }

        // Rent not paid after the configured day: this month only while something is unpaid.
        if config.shouldNotify(.lateRent) {
            let d = Int(config.rule(.lateRent).param)
            for m in (0...2).map({ current.adding($0) }) {
                let unpaid = store.tenants(in: m).filter { store.status(of: $0, in: m, now: now) != .paid }
                if m == current && unpaid.isEmpty { continue }
                let body = m == current && !unpaid.isEmpty
                    ? L("notif.late.body_names", unpaid.count, unpaid.prefix(3).map(\.name).joined(separator: ", "))
                    : L("notif.late.body", m.title())
                plan("late.\(m.id)", L("notif.late.title", d), body, on: day(m, d + 1))
            }
        }

        // The month's expected rent, on the configured day.
        if config.shouldNotify(.expectedRent) {
            let d = Int(config.rule(.expectedRent).param)
            for m in (0...2).map({ current.adding($0) }) {
                let t = store.totals(in: m)
                guard t.expected > 0 else { continue }
                plan("expected.\(m.id)", L("notif.expected.title", m.title()), L("notif.expected.body", t.expected.money, store.tenants(in: m).count), on: day(m, d))
            }
        }

        // Expenses falling due, the configured number of days before their month starts.
        if config.shouldNotify(.upcomingExpense) {
            let lead = Int(config.rule(.upcomingExpense).param)
            for offset in 1...6 {
                let target = current.adding(offset)
                let due = store.data.expenses.filter { $0.frequency != .monthly && $0.amount(in: target) > 0 && !$0.paidMonths.contains(target) }
                guard !due.isEmpty else { continue }
                let total = due.reduce(0) { $0 + $1.amount(in: target) }
                let names = due.sorted { $0.amount(in: target) > $1.amount(in: target) }.prefix(3).map(\.title).joined(separator: ", ")
                plan("exp.\(target.id)", L("notif.expenses.title", target.title()), L("notif.expenses.body", total.money, names),
                     on: cal.date(byAdding: .day, value: -lead, to: target.start))
            }
        }

        // Rooms and homes about to reach the vacancy limit.
        if config.shouldNotify(.vacancy) {
            let limit = Int(config.rule(.vacancy).param)
            for u in store.data.units where store.currentTenant(of: u.id, now: now) == nil {
                guard let last = store.tenants(of: u.id).compactMap(\.exitDate).max() else { continue }
                let name = store.property(u.propertyID).map { $0.kind == .rooms ? "\($0.name) · \(u.name)" : $0.name } ?? u.name
                plan("vacant.\(u.id.uuidString)", L("notif.vacant.title", name), L("notif.vacant.body", limit), on: cal.date(byAdding: .day, value: limit, to: last))
            }
        }

        for t in store.data.tenants {
            // Contracts ending.
            if config.shouldNotify(.contractEnding), t.isActive, let end = t.contractEnd {
                // At the chosen notice (months ahead) and again a month before the end.
                let lead = Int(config.rule(.contractEnding).param)
                for days in Set([lead, 30]).sorted(by: >) {
                    plan("contract\(days).\(t.id.uuidString)", L("notif.contract.title", t.name, days), L("notif.contract.body", end.short),
                         on: cal.date(byAdding: .day, value: -days, to: end))
                }
            }
            // Rent update.
            if config.shouldNotify(.rentUpdate), t.isActive, store.updateIndex(for: t) != .none, !store.isSeasonal(t),
               let next = store.nextAnniversary(of: t, now: now), !(t.rentChanges ?? []).contains(where: { $0.cycle == next.cycle }) {
                let days = Int(config.rule(.rentUpdate).param)
                plan("review.\(t.id.uuidString)", L("notif.review.title", t.name), L("notif.review.body", next.date.short), on: cal.date(byAdding: .day, value: -days, to: next.date))
            }
            // Fianza deposit: a week before the deadline.
            if config.shouldNotify(.depositFiling), case .pending(let deadline) = store.filingInfo(for: t, now: now).status {
                let days = 7
                plan("filing.\(t.id.uuidString)", L("notif.filing.title", t.name), L("notif.filing.body", deadline.short), on: cal.date(byAdding: .day, value: -days, to: deadline))
            }
        }
        return out
    }
}
