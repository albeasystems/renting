//
//  DashboardView.swift
//  Renting
//
//  Balance of a month, a calendar quarter or a year (income, expenses, net); the income of
//  all three side by side; the income-vs-expenses chart at the matching scale (monthly bars,
//  quarterly bars or yearly bars) with a quick view of the period; occupancy, alerts and the
//  income summary per property, room and tenant.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui
    @AppStorage("isProUnlocked") private var isPro = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 38

    enum Grouping: String, CaseIterable, Identifiable { case property, unit, tenant; var id: String { rawValue } }

    @State private var period = ReportPeriod(kind: .month, anchor: .current)
    @State private var propertyFilter: UUID?
    @State private var grouping: Grouping = .property
    @State private var showKPIs = false
    @State private var showQuick = false
    @State private var showOccupancy = false
    @State private var tileID: PeriodKind?

    private var totals: Totals { store.totals(period, property: propertyFilter) }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 14) {
                    if store.isDemo { demoBanner }
                    // A new landlord sees what to do next, not a wall of zeros.
                    SetupPrompt()
                    if store.setupStep != .addHome {
                        controls
                        hero
                        incomeCard
                        chartCard.id("debugChartCard")
                        occupancyCard
                        alertsCard
                        summarySection
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
            }
            #if DEBUG
            // Marketing captures only (marketing/capture.sh): `-debugScrollChart 1` scrolls to the chart.
            .task {
                guard ProcessInfo.processInfo.arguments.contains("-debugScrollChart") else { return }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(nil) { proxy.scrollTo("debugChartCard", anchor: .top) }
            }
            #endif
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("tab.dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { ui.tab = .fiscal } label: { Image(systemName: "doc.richtext") }
                        .accessibilityLabel(Text("reports.title"))
                    Button { ui.showAlerts = true } label: { Image(systemName: store.alerts().isEmpty ? "bell" : "bell.badge") }
                        .accessibilityLabel(Text("alerts.title"))
                }
            }
            .withSettingsButton()
            .sheet(isPresented: $showKPIs) { KPIInfoView(month: kpiMonth, property: propertyFilter) }
            .sheet(isPresented: $showQuick) { PeriodInfoView(period: period, property: propertyFilter) }
            .sheet(isPresented: $showOccupancy) { OccupancyInfoView() }
            .bannerInset(.dashboard, showsRewarded: !store.isEmpty)
        }
    }

    /// Month the KPI sheet explains: the selected month, or the last month of the period so far.
    private var kpiMonth: MonthKey { min(period.last, MonthKey.current) }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("", selection: Binding(get: { period.kind }, set: { period = period.with(kind: $0) })) {
                Text("period.month").tag(PeriodKind.month)
                Text("period.quarter").tag(PeriodKind.quarter)
                Text("period.year").tag(PeriodKind.year)
            }.pickerStyle(.segmented)

            HStack {
                Button { period = period.moved(by: -1) } label: { Image(systemName: "chevron.backward") }
                Spacer()
                Text(period.title).font(.headline).textCase(.none)
                Spacer()
                Button { period = period.moved(by: 1) } label: { Image(systemName: "chevron.forward") }
            }
            .padding(.horizontal, 4)

            Menu {
                Button("filter.all") { propertyFilter = nil }
                ForEach(store.data.properties) { p in Button(p.name) { propertyFilter = p.id } }
            } label: {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    if let id = propertyFilter, let p = store.property(id) { Text(p.name) } else { Text("filter.all") }
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(netTitle).font(.footnote).foregroundStyle(.secondary)
                    Button { showKPIs = true } label: { Image(systemName: "info.circle").font(.footnote) }
                        .accessibilityLabel(Text("kpi.info"))
                    Spacer()
                }
                Text(totals.net.signedMoney)
                    .font(.system(size: heroSize, weight: .bold, design: .rounded))
                    .foregroundStyle(totals.net >= 0 ? Color.income : Color.alert)
                    .minimumScaleFactor(0.6).lineLimit(1)
                if period.isOngoing {
                    Text("dash.to_date \(MonthKey.current.title())").font(.caption).foregroundStyle(.secondary)
                }
            }
            stackedAtLargeText(vertical: VStackLayout(alignment: .leading, spacing: 10), horizontal: HStackLayout(alignment: .top)) {
                KPI(title: "dash.collected", value: totals.collected.money, color: .income)
                KPI(title: "dash.expenses", value: totals.expenses.money, color: .expense)
                KPI(title: "dash.pending", value: totals.pending.money, color: totals.pending > 0 ? .alert : .secondary)
            }
        }
        .card()
    }

    /// Side by side normally; one under another at accessibility text sizes, where three
    /// columns would break words ("Col-lected") or cut the titles of the tiles.
    private func stackedAtLargeText<Content: View>(vertical: VStackLayout, horizontal: HStackLayout, @ViewBuilder content: () -> Content) -> some View {
        (typeSize.isAccessibilitySize ? AnyLayout(vertical) : AnyLayout(horizontal))(content)
    }

    private var netTitle: LocalizedStringKey {
        switch period.kind {
        case .month: "dash.net_month"
        case .quarter: "dash.net_quarter"
        case .year: "dash.net_year"
        }
    }

    // MARK: Income: month, quarter and year, one page each

    /// A carousel: one full-width page per scale (month, quarter, year), so the figures are big
    /// enough to read on a small phone. Swiping only looks; tapping a page selects that scale.
    private var incomeCard: some View {
        let tiles: [(kind: PeriodKind, period: ReportPeriod)] = PeriodKind.allCases.map { ($0, period.with(kind: $0)) }
        return VStack(alignment: .leading, spacing: 10) {
            Text("dash.income.title").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(tiles, id: \.kind) { tile in
                        incomeTile(tile.kind, tile.period)
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.92 }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $tileID)
            HStack(spacing: 6) {
                ForEach(PeriodKind.allCases, id: \.self) { kind in
                    Circle().fill(kind == (tileID ?? period.kind) ? Color.brand : Color.secondary.opacity(0.3)).frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity)
            Text("dash.income.note").font(.caption2).foregroundStyle(.secondary)
        }
        .card()
        .onAppear { tileID = period.kind }
        .onChange(of: period.kind) { _, kind in withAnimation { tileID = kind } }
    }

    private func incomeTile(_ kind: PeriodKind, _ p: ReportPeriod) -> some View {
        let t = store.totals(p, property: propertyFilter)
        let active = kind == period.kind
        let name: LocalizedStringKey = switch kind { case .month: "period.month"; case .quarter: "period.quarter"; case .year: "period.year" }
        return Button { period = p } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(tileTitle(p)).font(.subheadline.weight(.semibold)).foregroundStyle(active ? Color.brand : .secondary)
                    Spacer()
                    Text(name).font(.caption).foregroundStyle(.secondary)
                }
                Text(t.collected.money)
                    .font(.system(.title, design: .rounded, weight: .bold)).foregroundStyle(Color.income)
                    .lineLimit(1).minimumScaleFactor(0.6)
                ProgressView(value: min(t.collected, t.expected), total: max(t.expected, 1)).tint(Color.income)
                HStack {
                    Text(L("dash.income.rent", t.rent.money)).font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    if t.pending > 0.5 {
                        Text(L("dash.income.owed", t.pending.money)).font(.footnote.weight(.semibold)).foregroundStyle(Color.alert)
                    }
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(active ? Color.brand.opacity(0.10) : Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(active ? Color.brand : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    /// Short title of a tile: "oct 2026", "Q4 2026", "2026".
    private func tileTitle(_ p: ReportPeriod) -> String {
        switch p.kind {
        case .month: p.anchor.title(short: true)
        case .quarter, .year: p.title
        }
    }

    // MARK: Chart

    private var chartCard: some View {
        let points = store.chartPoints(for: period, property: propertyFilter)
        let labels = Dictionary(uniqueKeysWithValues: points.map { ($0.key, $0.label) })
        let barWidth: CGFloat = switch period.kind { case .month: 6; case .quarter: 22; case .year: 26 }
        let scale: LocalizedStringKey = switch period.kind { case .month: "dash.chart.monthly"; case .quarter: "dash.chart.quarterly"; case .year: "dash.chart.yearly" }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("dash.chart.title").font(.headline)
                    Text(scale).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { showQuick = true } label: { Image(systemName: "info.circle").font(.body) }
                    .accessibilityLabel(Text("quick.title"))
            }
            Chart {
                ForEach(points) { item in
                    BarMark(x: .value("m", item.key), y: .value("v", item.totals.collected), width: .fixed(barWidth))
                        .foregroundStyle(by: .value("t", "income"))
                        .position(by: .value("t", "income"))
                        .opacity(item.isSelected ? 1 : 0.45)
                    BarMark(x: .value("m", item.key), y: .value("v", item.totals.expenses), width: .fixed(barWidth))
                        .foregroundStyle(by: .value("t", "expense"))
                        .position(by: .value("t", "expense"))
                        .opacity(item.isSelected ? 1 : 0.45)
                }
            }
            .chartForegroundStyleScale(["income": Color.income, "expense": Color.expense])
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel { if let key = value.as(String.self) { Text(labels[key] ?? key).font(.caption2) } }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel { if let v = value.as(Double.self) { Text(v >= 1000 ? "\(Int(v / 1000))k" : "\(Int(v))") } }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let frame = proxy.plotFrame else { return }
                            let x = location.x - geo[frame].origin.x
                            if let key: String = proxy.value(atX: x), let hit = points.first(where: { $0.key == key }) { period = hit.target }
                        }
                }
            }
            .frame(height: 170)
            HStack(spacing: 16) {
                legend(.income, "dash.collected")
                legend(.expense, "dash.expenses")
                Spacer()
                Text("dash.chart.tap").font(.caption2).foregroundStyle(.tertiary)
            }
            .font(.caption)
        }
        .card()
    }

    private func legend(_ color: Color, _ key: LocalizedStringKey) -> some View {
        HStack(spacing: 6) { Circle().fill(color).frame(width: 8, height: 8); Text(key).foregroundStyle(.secondary) }
    }

    // MARK: Occupancy

    private var occupancyCard: some View {
        let occ = store.occupancy
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("dash.occupancy").font(.headline)
                Button { showOccupancy = true } label: { Image(systemName: "info.circle").font(.body) }
                    .accessibilityLabel(Text("occ.info.title"))
                Spacer()
                Text("\(occ.occupied)/\(occ.total)").font(.headline).foregroundStyle(Color.brand)
            }
            ForEach(store.data.properties) { p in
                let o = store.occupied(p.id)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(p.name).font(.subheadline)
                        Spacer()
                        Text("\(o.occupied)/\(o.total)").font(.subheadline).foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(o.occupied), total: Double(max(o.total, 1))).tint(o.occupied == o.total ? Color.income : Color.gold)
                }
            }
        }
        .card()
    }

    // MARK: Alerts

    @ViewBuilder private var alertsCard: some View {
        let alerts = store.alerts()
        if !alerts.isEmpty {
            Button { ui.showAlerts = true } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("alerts.title", systemImage: "bell.badge.fill").font(.headline).foregroundStyle(Color.alert)
                        Spacer()
                        Text("\(alerts.count)").font(.subheadline.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.alert.opacity(0.15), in: Capsule()).foregroundStyle(Color.alert)
                        if !isPro { Image(systemName: "lock.fill").font(.footnote).foregroundStyle(.secondary) }
                    }
                    if isPro {
                        ForEach(alerts.prefix(3)) { a in
                            HStack(spacing: 10) {
                                Image(systemName: a.icon).foregroundStyle(a.color).frame(width: 22)
                                Text(a.title).font(.subheadline).foregroundStyle(.primary).lineLimit(2).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                        }
                    } else {
                        Text("alerts.teaser").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                    }
                }
                .card()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Summary of the period

    private var summarySection: some View {
        let rows: [SummaryRow] = switch grouping {
        case .property: store.summaryByProperty(months: period.accountedMonths)
        case .unit: store.summaryByUnit(months: period.accountedMonths)
        case .tenant: store.summaryByTenant(months: period.accountedMonths)
        }
        let maxValue = max(rows.map(\.income).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("summary.title \(period.title)").font(.headline)
            Picker("", selection: $grouping) {
                Text("summary.property").tag(Grouping.property)
                Text("summary.unit").tag(Grouping.unit)
                Text("summary.tenant").tag(Grouping.tenant)
            }.pickerStyle(.segmented)

            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(row.title).font(.subheadline.weight(.semibold))
                            Text(row.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(row.income.money).font(.subheadline.weight(.semibold)).foregroundStyle(Color.income)
                            if grouping != .tenant {
                                Text(row.net.signedMoney).font(.caption).foregroundStyle(row.net >= 0 ? Color.secondary : Color.alert)
                            }
                        }
                    }
                    GeometryReader { geo in
                        Capsule().fill(Color.income.opacity(0.85)).frame(width: max(4, geo.size.width * row.income / maxValue), height: 5)
                    }.frame(height: 5)
                }
            }
            if rows.isEmpty { Text("common.empty").font(.footnote).foregroundStyle(.secondary) }
            if grouping != .tenant { Text("summary.net_note").font(.caption2).foregroundStyle(.secondary) }
        }
        .card()
    }

    private var demoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles").foregroundStyle(Color.gold)
            Text("demo.banner").font(.footnote)
            Spacer()
        }
        .padding(12)
        .background(Color.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
    }
}
