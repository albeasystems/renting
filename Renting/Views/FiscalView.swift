//
//  FiscalView.swift
//  Renting
//
//  The fiscal tab, for the Spanish income-tax return: rent income (utilities charged on
//  top are left out), the expense categories the landlord marks as deductible —
//  community, IBI, municipal taxes and the manager's fee by default — for the days each
//  home was let, building depreciation, the reduction of each contract (50–90 %, none
//  for seasonal lets) and the income imputed for the days a home stood empty. Free: rent
//  collected, the deductible expenses and the net before reductions. Subscription: the reductions,
//  depreciation, vacancy imputation, the choice of deductible categories and the PDF/CSV export
//  (which a rewarded video also unlocks for one hour).
//

import SwiftUI

struct FiscalView: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui
    @ObservedObject private var ads = AdsManager.shared
    @AppStorage("isProUnlocked") private var isPro = false
    @State private var year = MonthKey.current.year
    @State private var property: UUID?
    @State private var editingProperty: Property?
    @State private var showOtherCategories = false
    @State private var pdfURL: URL?
    @State private var csvURL: URL?
    @State private var fetching = false
    @State private var unavailable = false
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 34

    /// The advanced figures and settings come with the subscription.
    private var advanced: Bool { isPro }
    /// The report can also be unlocked for an hour by a rewarded video.
    private var unlocked: Bool { isPro || (ads.adFreeUntil.map { $0 > Date() } ?? false) }

    var body: some View {
        let figures = ReportService.figures(year: year, store: store, property: property)
        let t = Sums(figures)
        let netReduced = t.netReduced
        let supplies = t.supplies
        let amounts = Dictionary(store.expenseBreakdown(year: year, property: property).map { ($0.category, $0.amount) }, uniquingKeysWith: +)
        List {
            Section {
                Picker("reports.year", selection: $year) { ForEach(store.years, id: \.self) { Text(String($0)).tag($0) } }
                Picker("exp.property", selection: $property) {
                    Text("filter.all").tag(UUID?.none)
                    ForEach(store.data.properties) { Text($0.name).tag(UUID?.some($0.id)) }
                }
            }

            if advanced {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("fiscal.net_reduced").font(.footnote).foregroundStyle(.secondary)
                        Text(netReduced.signedMoney)
                            .font(.system(size: heroSize, weight: .bold, design: .rounded))
                            .foregroundStyle(netReduced >= 0 ? Color.income : Color.alert)
                            .minimumScaleFactor(0.6).lineLimit(1)
                        if t.imputed > 0.5 {
                            Text("fiscal.plus_imputed \(t.imputed.money)").font(.footnote).foregroundStyle(Color.expense)
                        }
                    }
                    .padding(.vertical, 4)
                    LabeledContent("pdf.income") { Text(t.income.money).foregroundStyle(Color.income) }
                    LabeledContent("pdf.expenses") { Text((-t.expenses).money) }
                    LabeledContent("pdf.depreciation") { Text((-t.depreciation).money) }
                    LabeledContent("pdf.net") { Text(t.net.money).fontWeight(.semibold) }
                    LabeledContent("fiscal.reduction") { Text((-t.reduction).money) }
                    LabeledContent("fiscal.net_reduced") { Text(netReduced.money).fontWeight(.bold).foregroundStyle(Color.brand) }
                } header: { Text("fiscal.summary \(String(year))") } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if supplies > 0 { Text("fiscal.supplies_excluded \(supplies.money)") }
                        if t.unpaidRent > 0.5 { Text("fiscal.unpaid \(t.unpaidRent.money)") }
                        if year == MonthKey.current.year { Text("fiscal.current_year") }
                    }
                }
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("fiscal.net_basic").font(.footnote).foregroundStyle(.secondary)
                        Text((t.income - t.expenses).signedMoney)
                            .font(.system(size: heroSize, weight: .bold, design: .rounded))
                            .foregroundStyle(t.income - t.expenses >= 0 ? Color.income : Color.alert)
                            .minimumScaleFactor(0.6).lineLimit(1)
                    }
                    .padding(.vertical, 4)
                    LabeledContent("pdf.income") { Text(t.income.money).foregroundStyle(Color.income) }
                    LabeledContent("pdf.expenses") { Text((-t.expenses).money) }
                    LabeledContent("fiscal.net_basic") { Text((t.income - t.expenses).money).fontWeight(.bold).foregroundStyle(Color.brand) }
                } header: { Text("fiscal.summary \(String(year))") } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if supplies > 0 { Text("fiscal.supplies_excluded \(supplies.money)") }
                        if t.unpaidRent > 0.5 { Text("fiscal.unpaid \(t.unpaidRent.money)") }
                        if year == MonthKey.current.year { Text("fiscal.current_year") }
                    }
                }
            }

            Section("fiscal.income") {
                if property == nil {
                    ForEach(figures, id: \.property.id) { f in
                        Button { property = f.property.id } label: {
                            HStack {
                                Image(systemName: f.property.kind.icon).foregroundStyle(Color.brand).frame(width: 24)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(f.property.name).foregroundStyle(.primary)
                                    Text(f.property.kind.label).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(f.income.money).foregroundStyle(.primary)
                            }
                        }
                    }
                } else if let f = figures.first {
                    if f.tenants.isEmpty { Text("pdf.none").foregroundStyle(.secondary) }
                    ForEach(f.tenants) { t in
                        LabeledContent {
                            Text(t.rent.money)
                        } label: {
                            Text(t.name)
                            Text(t.unit)
                        }
                    }
                }
            }

            if advanced {
                reductionSection(figures)
    
                Section {
                    ForEach(ExpenseCategory.allCases.filter { (amounts[$0] ?? 0) > 0 }.sorted { (amounts[$0] ?? 0) > (amounts[$1] ?? 0) }) { c in
                        categoryRow(c, amount: amounts[c] ?? 0)
                    }
                    DisclosureGroup("fiscal.other_categories", isExpanded: $showOtherCategories) {
                        ForEach(ExpenseCategory.allCases.filter { (amounts[$0] ?? 0) <= 0 }) { c in categoryRow(c, amount: 0) }
                    }
                    if supplies > 0 && ExpenseCategory.allCases.contains(where: { $0.isUtility && store.isDeductible($0) }) {
                        Label("fiscal.utilities_warning \(supplies.money)", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(Color.expense)
                    }
                    if t.vacantExpenses > 0.5 {
                        LabeledContent("fiscal.marked_total") { Text(t.markedExpenses.money) }
                        LabeledContent("fiscal.vacant_expenses") { Text((-t.vacantExpenses).money).foregroundStyle(.secondary) }
                    }
                    LabeledContent("fiscal.deductible_total") { Text(t.expenses.money).fontWeight(.semibold) }
                    if t.otherExpenses > 0.5 { LabeledContent("fiscal.not_deductible") { Text(t.otherExpenses.money).foregroundStyle(.secondary) } }
                } header: { Text("fiscal.deductible") } footer: { Text("fiscal.deductible.footer") }
    
                Section {
                    ForEach(figures, id: \.property.id) { f in imputationRow(f) }
                    LabeledContent("fiscal.imputed_total") { Text(t.imputed.money).fontWeight(.semibold) }
                } header: { Text("fiscal.imputation") } footer: { Text("fiscal.imputation.footer") }
    
                Section {
                    ForEach(figures, id: \.property.id) { f in
                        if let value = f.property.constructionValue {
                            LabeledContent {
                                Text(f.depreciation.money)
                            } label: {
                                Text(f.property.name)
                                Text("fiscal.construction_value \(value.money)")
                            }
                        } else {
                            Button { editingProperty = f.property } label: {
                                LabeledContent {
                                    Text("fiscal.add_value").foregroundStyle(Color.brand)
                                } label: {
                                    Text(f.property.name).foregroundStyle(.primary)
                                    Text("fiscal.no_value")
                                }
                            }
                        }
                    }
                } header: { Text("pdf.depreciation") } footer: { Text("fiscal.depreciation.footer") }
            } else {
                Section {
                    Label("fiscal.adv.title", systemImage: "lock.fill").font(.headline)
                    Text("fiscal.adv.text").font(.footnote).foregroundStyle(.secondary)
                    Button("pro.unlock") { ui.showPaywall = true }
                }
            }

            Section {
                if unlocked {
                    Button {
                        pdfURL = ReportService.makePDF(year: year, store: store, property: property)
                        csvURL = ReportService.makeCSV(year: year, store: store, property: property)
                    } label: {
                        Label("reports.generate", systemImage: "doc.badge.gearshape.fill")
                    }
                    if let pdfURL { ShareLink(item: pdfURL) { Label("reports.share_pdf", systemImage: "square.and.arrow.up") } }
                    if let csvURL { ShareLink(item: csvURL) { Label("reports.share_csv", systemImage: "tablecells") } }
                } else {
                    Label("reports.locked", systemImage: "lock.fill").font(.headline)
                    Button("pro.unlock") { ui.showPaywall = true }
                    Button {
                        guard !fetching else { return }
                        fetching = true
                        Task { let shown = await ads.showRewardedFetchingIfNeeded(); fetching = false; if !shown { unavailable = true } }
                    } label: {
                        HStack { Label("reports.watch", systemImage: "play.rectangle.fill"); Spacer(); if fetching { ProgressView() } }
                    }
                }
            } header: { Text("fiscal.export") } footer: { Text("reports.disclaimer") }
        }
        .navigationTitle("tab.fiscal")
        .onChange(of: year) { _, _ in pdfURL = nil; csvURL = nil }
        .onChange(of: property) { _, _ in pdfURL = nil; csvURL = nil }
        .sheet(item: $editingProperty) { PropertyFormView(property: $0) }
        .alert("rewarded.unavailable_title", isPresented: $unavailable) { Button("common.ok", role: .cancel) {} } message: { Text("rewarded.unavailable_message") }
    }

    /// Totals over the homes shown.
    private struct Sums {
        var income = 0.0, expenses = 0.0, markedExpenses = 0.0, vacantExpenses = 0.0, otherExpenses = 0.0
        var depreciation = 0.0, net = 0.0, reduction = 0.0, netReduced = 0.0, imputed = 0.0, supplies = 0.0, unpaidRent = 0.0

        init(_ figures: [ReportService.PropertyFigures]) {
            for f in figures {
                income += f.income; expenses += f.expenses; markedExpenses += f.markedExpenses
                vacantExpenses += f.vacantExpenses; otherExpenses += f.otherExpenses; depreciation += f.depreciation
                net += f.net; reduction += f.reduction; netReduced += f.netReduced; imputed += f.imputed
                supplies += f.supplies; unpaidRent += f.unpaidRent
            }
        }
    }

    // MARK: Reduction per contract

    /// Every contract with rent in the year and its reduction, changeable in place.
    private func reductionSection(_ figures: [ReportService.PropertyFigures]) -> some View {
        Section {
            ForEach(figures.flatMap(\.tenants)) { row in
                if let tenant = store.tenant(row.id) {
                    Menu {
                        Picker("tenant.reduction", selection: Binding(get: { tenant.reduction }, set: { var t = tenant; t.reduction = $0; store.save(t) })) {
                            Text("red.auto \(store.automaticReduction(for: tenant).short)").tag(RentReduction?.none)
                            ForEach(RentReduction.allCases) { Text($0.label).tag(RentReduction?.some($0)) }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.name).foregroundStyle(.primary)
                                Text(row.reduction.label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Pill(text: LocalizedStringKey(row.reduction.short), color: row.reduction == .none ? .gray : .brand)
                            Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            LabeledContent("fiscal.reduction_total") { Text(Sums(figures).reduction.money).fontWeight(.semibold) }
        } header: { Text("fiscal.reduction_section") } footer: { Text("red.footer") }
    }

    // MARK: Imputed income

    @ViewBuilder
    private func imputationRow(_ f: ReportService.PropertyFigures) -> some View {
        if f.property.ownerResidence {
            LabeledContent { Text(0.0.money).foregroundStyle(.secondary) } label: { Text(f.property.name); Text("fiscal.own_home") }
        } else if f.vacantDays == 0 {
            LabeledContent { Text(0.0.money).foregroundStyle(.secondary) } label: { Text(f.property.name); Text("fiscal.always_let") }
        } else if f.property.cadastralValue == nil {
            Button { editingProperty = f.property } label: {
                LabeledContent {
                    Text("fiscal.add_cadastral").foregroundStyle(Color.brand)
                } label: {
                    Text(f.property.name).foregroundStyle(.primary)
                    Text("fiscal.vacant_days \(f.vacantDays)")
                }
            }
        } else {
            LabeledContent {
                Text(f.imputed.money).foregroundStyle(Color.expense)
            } label: {
                Text(f.property.name)
                Text(ReportService.imputationDetail(f))
            }
        }
    }

    // MARK: Deductible categories

    /// A category with its yearly amount; tap to count it as deductible or not.
    private func categoryRow(_ c: ExpenseCategory, amount: Double) -> some View {
        let on = store.isDeductible(c)
        return Button { store.setDeductible(c, !on); UISelectionFeedbackGenerator().selectionChanged() } label: {
            HStack(spacing: 12) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(on ? Color.brand : Color.secondary)
                Image(systemName: c.icon).font(.footnote).foregroundStyle(.white).frame(width: 28, height: 28)
                    .background(c.color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(c.label).foregroundStyle(.primary)
                    if !on && c.usuallyDeductible { Text("fiscal.usually").font(.caption2).foregroundStyle(Color.gold) }
                }
                Spacer()
                if amount > 0 {
                    Text(amount.money).foregroundStyle(on ? .primary : .secondary).strikethrough(!on)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
