//
//  KPIInfoView.swift
//  Renting
//
//  The "info" behind the monthly net profit on the Summary tab: how it is made (what comes
//  in minus what goes out) and the KPIs that explain it — collection rate, occupancy,
//  where the money goes, margin and whether the utilities charged cover the bills — each
//  with a 12-month chart, what it means and how to improve it.
//

import SwiftUI
import Charts

struct MonthKPI: Identifiable {
    let month: MonthKey
    let collected: Double
    let rent: Double
    let supplies: Double
    let expected: Double
    let expenses: Double
    let occupancy: Double
    let utilityBills: Double

    var id: Int { month.id }
    var net: Double { collected - expenses }
    var collectionRate: Double? { expected > 0 ? min(collected / expected, 1.5) : nil }
    var margin: Double? { collected > 0 ? net / collected : nil }
    var coverage: Double? { utilityBills > 0 ? supplies / utilityBills : nil }
}

extension RentalStore {
    /// Share of rooms/homes with a tenant in `month`.
    func occupancyRate(in month: MonthKey, property: UUID? = nil) -> Double {
        let units = data.units.filter { property == nil || $0.propertyID == property }
        guard !units.isEmpty else { return 0 }
        let occupied = units.filter { u in tenants(of: u.id).contains { $0.isActive(in: month) } }.count
        return Double(occupied) / Double(units.count)
    }

    /// The `count` months ending at `end`, oldest first.
    func kpiSeries(ending end: MonthKey, count: Int = 12, property: UUID? = nil) -> [MonthKPI] {
        (0..<count).reversed().map { back in
            let m = end.adding(-back)
            let t = totals(in: m, property: property)
            let bills = charges(in: m, property: property).filter { $0.category.isUtility }.reduce(0) { $0 + $1.amount }
            return MonthKPI(month: m, collected: t.collected, rent: t.rent, supplies: t.supplies, expected: t.expected,
                            expenses: t.expenses, occupancy: occupancyRate(in: m, property: property), utilityBills: bills)
        }
    }
}

struct KPIInfoView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let month: MonthKey
    let property: UUID?

    private func axis() -> some AxisContent {
        AxisMarks(values: .stride(by: .month)) { _ in
            AxisValueLabel(format: .dateTime.locale(AppLanguage.shared.locale).month(.narrow)).font(.caption2)
        }
    }

    private func percent(_ v: Double?) -> String {
        guard let v else { return "—" }
        return v.formatted(.percent.precision(.fractionLength(0)).locale(AppLanguage.shared.locale))
    }

    var body: some View {
        let series = store.kpiSeries(ending: month, property: property)
        let now = series.last ?? MonthKPI(month: month, collected: 0, rent: 0, supplies: 0, expected: 0, expenses: 0, occupancy: 0, utilityBills: 0)
        let average = series.reduce(0) { $0 + $1.net } / Double(max(series.count, 1))
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    equation(now)
                    netCard(series, now, average)
                    collectionCard(series, now)
                    occupancyCard(series, now)
                    mixCard(now)
                    marginCard(series, now)
                    coverageCard(series, now)
                    Text("kpi.footer").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 8)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("kpi.title \(month.title())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
        }
    }

    // MARK: How the net profit is made

    private func equation(_ now: MonthKPI) -> some View {
        let share = now.collected > 0 ? min(max(now.expenses / now.collected, 0), 1) : 0
        return VStack(alignment: .leading, spacing: 12) {
            Text("kpi.eq.title").font(.headline)
            HStack(alignment: .top, spacing: 6) {
                eqTerm("dash.collected", now.collected, .income)
                Text("−").font(.title3.weight(.bold)).foregroundStyle(.secondary).padding(.top, 14)
                eqTerm("dash.expenses", now.expenses, .expense)
                Text("=").font(.title3.weight(.bold)).foregroundStyle(.secondary).padding(.top, 14)
                eqTerm("dash.net_month", now.net, now.net >= 0 ? .income : .alert, signed: true)
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    Capsule().fill(Color.expense).frame(width: max(share * geo.size.width - 1, share > 0 ? 6 : 0))
                    Capsule().fill(Color.income)
                }
            }
            .frame(height: 10)
            Text("kpi.eq.split \(Int((share * 100).rounded())) \(Int(((1 - share) * 100).rounded()))").font(.caption).foregroundStyle(.secondary)
            Text("kpi.eq.what").font(.footnote)
            HStack(spacing: 8) {
                Pill(text: "kpi.eq.rent \(now.rent.money)", color: .income)
                if now.supplies > 0 { Pill(text: "kpi.eq.supplies \(now.supplies.money)", color: .teal) }
            }
            Text("kpi.eq.note").font(.caption).foregroundStyle(.secondary)
        }
        .card()
    }

    private func eqTerm(_ title: LocalizedStringKey, _ value: Double, _ color: Color, signed: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary).lineLimit(2).minimumScaleFactor(0.8)
            Text(signed ? value.signedMoney : value.money).font(.subheadline.weight(.bold)).foregroundStyle(color).minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Cards

    private func netCard(_ series: [MonthKPI], _ now: MonthKPI, _ average: Double) -> some View {
        KPICard(icon: "eurosign.circle.fill", color: .income, title: "kpi.net.title", value: now.net.signedMoney,
                valueColor: now.net >= 0 ? .income : .alert, caption: L("kpi.net.avg", average.money), what: "kpi.net.what", how: "kpi.net.how") {
            Chart {
                ForEach(series) { p in
                    BarMark(x: .value("m", p.month.start, unit: .month), y: .value("v", p.net))
                        .foregroundStyle(p.net >= 0 ? Color.income : Color.alert)
                        .opacity(p.month == month ? 1 : 0.55)
                }
                RuleMark(y: .value("avg", average)).foregroundStyle(.secondary).lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            .chartXAxis { axis() }
        }
    }

    private func collectionCard(_ series: [MonthKPI], _ now: MonthKPI) -> some View {
        let rate = now.collectionRate
        let good = (rate ?? 1) >= 0.95
        return KPICard(icon: "checkmark.circle.fill", color: .brand, title: "kpi.coll.title", value: percent(rate),
                       valueColor: good ? .income : .expense, caption: L("kpi.coll.of", now.collected.money, now.expected.money),
                       what: "kpi.coll.what", how: "kpi.coll.how") {
            Chart {
                ForEach(series.filter { $0.collectionRate != nil }) { p in
                    LineMark(x: .value("m", p.month.start, unit: .month), y: .value("v", (p.collectionRate ?? 0) * 100))
                        .foregroundStyle(Color.brand).interpolationMethod(.monotone)
                    PointMark(x: .value("m", p.month.start, unit: .month), y: .value("v", (p.collectionRate ?? 0) * 100))
                        .foregroundStyle(Color.brand).symbolSize(p.month == month ? 60 : 16)
                }
                RuleMark(y: .value("goal", 95)).foregroundStyle(Color.income.opacity(0.7)).lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .annotation(position: .top, alignment: .trailing) { Text("95 %").font(.caption2).foregroundStyle(Color.income) }
            }
            .chartYScale(domain: 40...105)
            .chartXAxis { axis() }
        }
    }

    private func occupancyCard(_ series: [MonthKPI], _ now: MonthKPI) -> some View {
        let units = store.data.units.filter { property == nil || $0.propertyID == property }
        let vacant = units.filter { store.currentTenant(of: $0.id) == nil }
        let lost = vacant.reduce(0) { $0 + $1.listRent }
        return KPICard(icon: "bed.double.fill", color: .gold, title: "kpi.occ.title", value: percent(now.occupancy),
                       valueColor: now.occupancy >= 0.9 ? .income : .expense,
                       caption: vacant.isEmpty ? L("kpi.occ.full") : L("kpi.occ.lost", vacant.count, lost.money),
                       what: "kpi.occ.what", how: "kpi.occ.how") {
            Chart(series) { p in
                AreaMark(x: .value("m", p.month.start, unit: .month), y: .value("v", p.occupancy * 100))
                    .foregroundStyle(LinearGradient(colors: [Color.gold.opacity(0.5), Color.gold.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("m", p.month.start, unit: .month), y: .value("v", p.occupancy * 100))
                    .foregroundStyle(Color.gold).interpolationMethod(.monotone)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis { axis() }
        }
    }

    private func mixCard(_ now: MonthKPI) -> some View {
        let all = Dictionary(grouping: store.charges(in: month, property: property), by: \.category).map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
        let top = Array(all.prefix(5))
        let rest = all.dropFirst(5).reduce(0) { $0 + $1.1 }
        let slices: [(name: String, amount: Double, color: Color)] =
            top.map { ($0.0.name, $0.1, $0.0.color) } + (rest > 0 ? [(L("cat.other"), rest, Color.gray)] : [])
        let total = max(now.expenses, 1)
        return KPICard(icon: "chart.pie.fill", color: .expense, title: "kpi.mix.title", value: now.expenses.money, valueColor: .expense,
                       caption: slices.first.map { L("kpi.mix.top", $0.name, Int(($0.amount / total * 100).rounded())) } ?? L("kpi.mix.none"),
                       what: "kpi.mix.what", how: "kpi.mix.how", chartHeight: 150) {
            HStack(spacing: 14) {
                Chart(slices, id: \.name) { s in
                    SectorMark(angle: .value("v", s.amount), innerRadius: .ratio(0.62), angularInset: 1.5).foregroundStyle(s.color)
                }
                .frame(width: 130)
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(slices, id: \.name) { s in
                        HStack(spacing: 6) {
                            Circle().fill(s.color).frame(width: 8, height: 8)
                            Text(s.name).font(.caption).lineLimit(1)
                            Spacer(minLength: 2)
                            Text("\(Int((s.amount / total * 100).rounded())) %").font(.caption.weight(.semibold)).monospacedDigit()
                        }
                    }
                }
            }
        }
    }

    private func marginCard(_ series: [MonthKPI], _ now: MonthKPI) -> some View {
        KPICard(icon: "percent", color: .purple, title: "kpi.margin.title", value: percent(now.margin),
                valueColor: (now.margin ?? 0) >= 0.3 ? .income : ((now.margin ?? 0) >= 0 ? .expense : .alert),
                caption: now.margin.map { L("kpi.margin.per100", Int(($0 * 100).rounded())) } ?? "", what: "kpi.margin.what", how: "kpi.margin.how") {
            Chart(series.filter { $0.margin != nil }) { p in
                LineMark(x: .value("m", p.month.start, unit: .month), y: .value("v", (p.margin ?? 0) * 100))
                    .foregroundStyle(Color.purple).interpolationMethod(.monotone)
                PointMark(x: .value("m", p.month.start, unit: .month), y: .value("v", (p.margin ?? 0) * 100))
                    .foregroundStyle(Color.purple).symbolSize(p.month == month ? 60 : 16)
            }
            .chartXAxis { axis() }
        }
    }

    private func coverageCard(_ series: [MonthKPI], _ now: MonthKPI) -> some View {
        let recent = Array(series.suffix(6))
        let covered = (now.coverage ?? 1) >= 1
        return KPICard(icon: "bolt.fill", color: .yellow, title: "kpi.cov.title", value: percent(now.coverage),
                       valueColor: now.coverage == nil ? .secondary : (covered ? .income : .alert),
                       caption: now.utilityBills > 0 ? L("kpi.cov.of", now.supplies.money, now.utilityBills.money) : L("kpi.cov.none"),
                       what: "kpi.cov.what", how: "kpi.cov.how") {
            Chart {
                ForEach(recent) { p in
                    BarMark(x: .value("m", p.month.start, unit: .month), y: .value("v", p.supplies))
                        .foregroundStyle(by: .value("t", "charged")).position(by: .value("t", "charged"))
                    BarMark(x: .value("m", p.month.start, unit: .month), y: .value("v", p.utilityBills))
                        .foregroundStyle(by: .value("t", "bills")).position(by: .value("t", "bills"))
                }
            }
            .chartForegroundStyleScale(["charged": Color.teal, "bills": Color.expense])
            .chartLegend(.hidden)
            .chartXAxis { axis() }
        }
    }
}

/// One KPI: value, a 12-month chart, what it means and, expandable, how to read and improve it.
private struct KPICard<Chart: View>: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    let value: String
    var valueColor: Color = .primary
    var caption = ""
    let what: LocalizedStringKey
    let how: LocalizedStringKey
    var chartHeight: CGFloat = 120
    @ViewBuilder var chart: Chart

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.footnote).foregroundStyle(.white).frame(width: 28, height: 28)
                    .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(.subheadline.weight(.semibold))
                    if !caption.isEmpty { Text(caption).font(.caption2).foregroundStyle(.secondary).lineLimit(2) }
                }
                Spacer()
                Text(value).font(.title3.weight(.bold)).foregroundStyle(valueColor).minimumScaleFactor(0.6).lineLimit(1)
            }
            chart.frame(height: chartHeight)
            Text(what).font(.footnote)
            DisclosureGroup("kpi.how_title") {
                Text(how).font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
            }
            .font(.footnote.weight(.semibold))
            .tint(Color.brand)
        }
        .card()
    }
}
