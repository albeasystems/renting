//
//  Period.swift
//  Renting
//
//  The three periods the Summary tab can show — a month, a calendar quarter (Q1 starts on
//  1 January, so Jan–Mar, Apr–Jun, Jul–Sep, Oct–Dec) and a year — and what is built on them:
//  totals, the income-vs-expenses chart and the quick view of one period's income and expenses.
//

import Foundation

enum PeriodKind: String, CaseIterable, Identifiable {
    case month, quarter, year
    var id: String { rawValue }
}

/// A period of the calendar, set by a kind and any month inside it.
struct ReportPeriod: Equatable {
    var kind: PeriodKind
    var anchor: MonthKey

    /// 1...4. January to March is the first quarter of every year.
    var quarter: Int { (anchor.month - 1) / 3 + 1 }
    var year: Int { anchor.year }

    var months: [MonthKey] {
        switch kind {
        case .month: [anchor]
        case .quarter: (0..<3).map { MonthKey(year: anchor.year, month: (quarter - 1) * 3 + 1 + $0) }
        case .year: MonthKey.months(of: anchor.year)
        }
    }

    var first: MonthKey { months.first ?? anchor }
    var last: MonthKey { months.last ?? anchor }

    /// A quarter or a year that has started and not finished: its figures are "to date".
    var isOngoing: Bool { kind != .month && first <= MonthKey.current && last > MonthKey.current }

    /// The months that count in the figures. A running quarter or year only counts up to the
    /// current month, so the expenses still to come do not make the period look like a loss; a
    /// period that has not started yet shows its whole schedule.
    var accountedMonths: [MonthKey] {
        let past = months.filter { $0 <= MonthKey.current }
        return past.isEmpty ? months : past
    }

    /// The same kind of period, `steps` periods away.
    func moved(by steps: Int) -> ReportPeriod {
        let months = switch kind { case .month: 1; case .quarter: 3; case .year: 12 }
        return ReportPeriod(kind: kind, anchor: anchor.adding(steps * months))
    }

    /// Does `other` (a month) fall inside this period?
    func contains(_ month: MonthKey) -> Bool { months.contains(month) }

    /// "October 2026", "Q4 2026" or "2026".
    var title: String {
        switch kind {
        case .month: anchor.title()
        case .quarter: L("period.quarter_title", quarter, String(year))
        case .year: String(year)
        }
    }

    /// A period of kind `kind` that contains the same anchor month.
    func with(kind: PeriodKind) -> ReportPeriod { ReportPeriod(kind: kind, anchor: anchor) }

    static func quarter(_ q: Int, of year: Int) -> ReportPeriod {
        ReportPeriod(kind: .quarter, anchor: MonthKey(year: year, month: (q - 1) * 3 + 1))
    }
}

/// One bar group of the income-vs-expenses chart.
struct ChartPoint: Identifiable {
    let key: String
    let label: String
    let totals: Totals
    let isSelected: Bool
    /// The period that a tap on this bar selects.
    let target: ReportPeriod
    var id: String { key }
}

/// A line of the quick view: what a tenant paid, or what an expense category cost.
struct QuickRow: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let amount: Double
    /// Still owed (rent not collected) or still to pay (expenses not paid).
    let outstanding: Double
    /// Set for expenses: gives the icon and colour.
    let category: ExpenseCategory?
}

extension RentalStore {

    // MARK: Totals

    /// Totals over several months. Rent that is not due yet (future months) is not "pending".
    func totals(months: [MonthKey], property: UUID? = nil) -> Totals {
        let current = MonthKey.current
        return months.reduce(Totals()) { acc, m in
            var t = totals(in: m, property: property)
            if m > current { t.expected = 0 }
            return acc + t
        }
    }

    func totals(_ period: ReportPeriod, property: UUID? = nil) -> Totals { totals(months: period.accountedMonths, property: property) }

    // MARK: Chart

    /// The bars to draw: months of the year, the four quarters of the year, or one bar per year,
    /// depending on the period selected. The selected one is flagged.
    func chartPoints(for period: ReportPeriod, property: UUID? = nil) -> [ChartPoint] {
        switch period.kind {
        case .month:
            return MonthKey.months(of: period.year).map { m in
                ChartPoint(key: String(format: "%02d", m.month), label: m.monthName(narrow: true), totals: totals(in: m, property: property),
                           isSelected: m == period.anchor, target: ReportPeriod(kind: .month, anchor: m))
            }
        case .quarter:
            return (1...4).map { q in
                let target = ReportPeriod.quarter(q, of: period.year)
                return ChartPoint(key: "Q\(q)", label: L("period.q_short", q), totals: totals(target, property: property),
                                  isSelected: q == period.quarter, target: target)
            }
        case .year:
            let current = MonthKey.current.year
            let last = max(current, period.year)
            let first = min(years.last ?? last, period.year, last - 2)
            return (first...last).map { y in
                let target = ReportPeriod(kind: .year, anchor: MonthKey(year: y, month: min(max(period.anchor.month, 1), 12)))
                return ChartPoint(key: String(y), label: String(y), totals: totals(target, property: property),
                                  isSelected: y == period.year, target: target)
            }
        }
    }

    // MARK: Summaries over a period (income per home, room and tenant)

    func summaryByProperty(months: [MonthKey]) -> [SummaryRow] {
        data.properties.map { p in
            let t = totals(months: months, property: p.id)
            return SummaryRow(id: p.id, title: p.name, subtitle: p.city, income: t.collected, expected: t.expected, expenses: t.expenses)
        }.sorted { $0.net > $1.net }
    }

    /// Income per room; expenses assigned to a room directly, an equal share of the expenses
    /// of the whole property and the manager fee on the room's own rent.
    func summaryByUnit(months: [MonthKey]) -> [SummaryRow] {
        data.units.compactMap { u in
            guard let p = property(u.propertyID) else { return nil }
            let ts = tenants(of: u.id)
            let paid = ts.flatMap { t in months.compactMap { payment(of: t.id, in: $0) } }
            let income = paid.reduce(0.0) { $0 + $1.amount }
            let fee = paid.reduce(0.0) { $0 + split($1).rent } * (p.management?.rate ?? 0)
            let expected = ts.reduce(0.0) { acc, t in
                acc + months.filter { t.isActive(in: $0) && $0 <= MonthKey.current }.reduce(0.0) { $0 + due(of: t, in: $1) }
            }
            let count = Double(max(1, units(of: p.id).count))
            let expenses = data.expenses.filter { $0.propertyID == p.id }.reduce(0.0) { acc, e in
                let total = months.reduce(0.0) { $0 + e.amount(in: $1) }
                if let target = e.unitID { return acc + (target == u.id ? total : 0) }
                return acc + total / count
            } + fee
            return SummaryRow(id: u.id, title: u.name, subtitle: p.name, income: income, expected: expected, expenses: expenses)
        }.sorted { $0.net > $1.net }
    }

    func summaryByTenant(months: [MonthKey]) -> [SummaryRow] {
        data.tenants.compactMap { t in
            let income = months.reduce(0.0) { $0 + (payment(of: t.id, in: $1)?.amount ?? 0) }
            let expected = months.filter { t.isActive(in: $0) && $0 <= MonthKey.current }.reduce(0.0) { $0 + due(of: t, in: $1) }
            guard income > 0 || expected > 0 else { return nil }
            return SummaryRow(id: t.id, title: t.name, subtitle: unitLabel(t), income: income, expected: expected, expenses: 0)
        }.sorted { $0.income > $1.income }
    }

    func expenseBreakdown(months: [MonthKey], property: UUID? = nil) -> [(category: ExpenseCategory, amount: Double)] {
        var by: [ExpenseCategory: Double] = [:]
        for m in months {
            for c in charges(in: m, property: property) { by[c.category, default: 0] += c.amount }
        }
        return by.filter { $0.value > 0 }.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }

    // MARK: Quick view

    /// What each tenant paid in the period, with what is still owed; most paid first.
    func incomeRows(_ period: ReportPeriod, property: UUID? = nil) -> [QuickRow] {
        summaryByTenant(months: period.accountedMonths)
            .filter { row in property == nil || tenant(row.id).flatMap { propertyID(ofTenant: $0) } == property }
            .map { row in
                QuickRow(id: row.id.uuidString, title: row.title, subtitle: row.subtitle, amount: row.income,
                         outstanding: max(0, row.expected - row.income), category: nil)
            }
    }

    /// The expenses of the period by category, with what is still unpaid; biggest first.
    func expenseRows(_ period: ReportPeriod, property: UUID? = nil) -> [QuickRow] {
        var amount: [ExpenseCategory: Double] = [:]
        var unpaid: [ExpenseCategory: Double] = [:]
        for m in period.accountedMonths {
            for c in charges(in: m, property: property) {
                amount[c.category, default: 0] += c.amount
                if !c.isPaid && m <= MonthKey.current { unpaid[c.category, default: 0] += c.amount }
            }
        }
        return amount.filter { $0.value > 0 }.sorted { $0.value > $1.value }.map { cat, value in
            QuickRow(id: cat.rawValue, title: cat.name, subtitle: "", amount: value, outstanding: unpaid[cat] ?? 0, category: cat)
        }
    }

    /// Every expense of one month (IBI, electricity, the manager's fee…), biggest first, with
    /// what has not been paid yet.
    func chargeRows(in month: MonthKey, property: UUID? = nil) -> [QuickRow] {
        charges(in: month, property: property).sorted { $0.amount > $1.amount }.map { c in
            QuickRow(id: c.id, title: c.title, subtitle: self.property(c.propertyID)?.name ?? "", amount: c.amount,
                     outstanding: !c.isPaid && month <= MonthKey.current ? c.amount : 0, category: c.category)
        }
    }
}
