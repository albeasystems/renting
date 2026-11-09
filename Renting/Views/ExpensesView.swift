//
//  ExpensesView.swift
//  Renting
//
//  Recurring and one-off expenses (community, manager, garbage/waste tax, IBI,
//  insurance, utilities…) with monthly / quarterly / annual frequency. Month view =
//  checklist to tick what has been paid; year view = a 12-month matrix of every
//  expense; list = the expenses themselves and what falls due next. A manager on
//  commission shows up as one more monthly charge, computed on the rent collected.
//

import SwiftUI

struct ExpensesView: View {
    @Environment(RentalStore.self) private var store
    var propertyFilter: UUID?

    enum Mode: String, CaseIterable, Identifiable { case month, year, list; var id: String { rawValue } }
    @State private var mode: Mode = .month
    @State private var month = MonthKey.current
    @State private var year = MonthKey.current.year
    @State private var frequency: Frequency?
    @State private var property: UUID?
    @State private var editing: Expense?
    @State private var editingProperty: Property?
    @State private var actual: Charge?
    @State private var showNew = false

    private var embedded: Bool { propertyFilter != nil }
    private var activeProperty: UUID? { propertyFilter ?? property }

    var body: some View {
        if embedded { content } else { NavigationStack { content.withSettingsButton().bannerInset(.expenses) } }
    }

    private var content: some View {
        let unpaid = store.unpaidCharges(property: activeProperty)
        return ScrollView {
            VStack(spacing: 14) {
                HStack(alignment: .top) {
                    KPI(title: "exp.this_month", value: store.expenseTotal(in: .current, property: activeProperty).money, color: .expense)
                    KPI(title: "exp.year_total \(String(MonthKey.current.year))", value: store.totals(year: MonthKey.current.year, property: activeProperty).expenses.money, color: .expense)
                    KPI(title: "exp.unpaid", value: unpaid.reduce(0) { $0 + $1.amount }.money, color: unpaid.isEmpty ? .secondary : .alert)
                }
                .card()

                if !embedded {
                    Menu {
                        Button("filter.all") { property = nil }
                        ForEach(store.data.properties) { p in Button(p.name) { property = p.id } }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            if let id = property, let p = store.property(id) { Text(p.name) } else { Text("filter.all") }
                            Image(systemName: "chevron.down").font(.caption2)
                        }.font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Picker("", selection: $mode) {
                    Text("period.month").tag(Mode.month)
                    Text("period.year").tag(Mode.year)
                    Text("exp.mode.list").tag(Mode.list)
                }
                .pickerStyle(.segmented)

                switch mode {
                case .month: monthView(overdue: unpaid.filter { $0.month < .current })
                case .year: yearView
                case .list: listView
                }
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(embedded ? "props.expenses" : "tab.expenses")
        .navigationBarTitleDisplayMode(embedded ? .inline : .automatic)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNew = true } label: { Image(systemName: "plus") }.accessibilityLabel(Text("exp.add"))
            }
        }
        .sheet(isPresented: $showNew) { ExpenseFormView(expense: nil, defaultProperty: activeProperty) }
        .sheet(item: $editing) { ExpenseFormView(expense: $0, defaultProperty: nil) }
        .sheet(item: $editingProperty) { PropertyFormView(property: $0) }
        .sheet(item: $actual) { ActualBillSheet(charge: $0) }
    }

    private func open(_ charge: Charge) {
        switch charge.source {
        case .expense(let id): editing = store.data.expenses.first { $0.id == id }
        case .management(let id): editingProperty = store.property(id)
        }
    }

    // MARK: Month checklist

    private func monthView(overdue: [Charge]) -> some View {
        let charges = store.charges(in: month, property: activeProperty).sorted { $0.amount > $1.amount }
        let total = charges.reduce(0) { $0 + $1.amount }
        let paid = charges.filter(\.isPaid).reduce(0) { $0 + $1.amount }
        let grouped = Dictionary(grouping: charges, by: \.propertyID)
        return VStack(spacing: 14) {
            HStack {
                Button { month = month.adding(-1) } label: { Image(systemName: "chevron.backward") }
                Spacer()
                Text(month.title()).font(.headline)
                Spacer()
                Button { month = month.adding(1) } label: { Image(systemName: "chevron.forward") }
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("exp.progress").font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(paid.money) / \(total.money)").font(.subheadline.weight(.semibold))
                }
                ProgressView(value: paid, total: max(total, 1)).tint(Color.income)
                if total - paid > 0.005 {
                    HStack {
                        Text("exp.to_pay \((total - paid).money)").font(.footnote).foregroundStyle(month < .current ? Color.alert : .secondary)
                        Spacer()
                        Button("exp.mark_all") {
                            store.setPaid(charges.filter { !$0.isPaid }, true)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        .font(.footnote.weight(.semibold))
                    }
                }
            }
            .card()

            if month == .current && !overdue.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Label("exp.overdue_title", systemImage: "exclamationmark.circle.fill")
                        .font(.footnote.weight(.semibold)).foregroundStyle(Color.alert).padding(.bottom, 8)
                    ForEach(overdue.suffix(6)) { c in
                        ChargeRow(charge: c, showsMonth: true, onOpen: { open(c) }, onActual: { actual = c })
                        if c.id != overdue.last?.id { Divider().padding(.vertical, 6) }
                    }
                }
                .card()
            }

            if charges.isEmpty {
                // "Nothing to pay" is good news only when expenses exist; with none entered it is a first step.
                if store.data.expenses.isEmpty && store.data.properties.allSatisfy({ $0.management == nil }) {
                    EmptyState(icon: "creditcard", title: "exp.empty.title", message: "exp.empty.message", actionTitle: "exp.add", action: { showNew = true })
                } else {
                    EmptyState(icon: "checkmark.circle", title: "exp.month_empty.title", message: "exp.month_empty.message")
                }
            }

            ForEach(store.data.properties.filter { grouped[$0.id] != nil }) { p in
                VStack(alignment: .leading, spacing: 0) {
                    Text(p.name).font(.footnote.weight(.semibold)).foregroundStyle(.secondary).padding(.bottom, 8)
                    ForEach(grouped[p.id] ?? []) { c in
                        ChargeRow(charge: c, onOpen: { open(c) }, onActual: { actual = c })
                        if c.id != grouped[p.id]?.last?.id { Divider().padding(.vertical, 6) }
                    }
                }
                .card()
            }
        }
    }

    // MARK: Year matrix

    private struct MatrixRow: Identifiable {
        let source: Charge.Source
        let title: String
        let subtitle: String
        let category: ExpenseCategory
        var cells: [MonthKey: Charge] = [:]
        var id: Charge.Source { source }
    }

    private var yearView: some View {
        let months = MonthKey.months(of: year)
        var rows: [Charge.Source: MatrixRow] = [:]
        for m in months {
            for c in store.charges(in: m, property: activeProperty) {
                rows[c.source, default: MatrixRow(source: c.source, title: c.title, subtitle: store.property(c.propertyID)?.name ?? "", category: c.category)].cells[m] = c
            }
        }
        let sorted = rows.values.sorted { ($0.subtitle, $0.title) < ($1.subtitle, $1.title) }
        let balance = store.suppliesBalance(year: year, property: activeProperty)
        return VStack(spacing: 14) {
            HStack {
                Button { year -= 1 } label: { Image(systemName: "chevron.backward") }
                Spacer()
                Text(String(year)).font(.headline)
                Spacer()
                Button { year += 1 } label: { Image(systemName: "chevron.forward") }
            }
            .padding(.horizontal, 4)

            if sorted.isEmpty {
                EmptyState(icon: "creditcard", title: "exp.empty.title", message: "exp.empty.message", actionTitle: "exp.add", action: { showNew = true })
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    Grid(horizontalSpacing: 2, verticalSpacing: 10) {
                        GridRow {
                            Text("").frame(width: 96)
                            ForEach(months) { m in Text(m.monthName(narrow: true)).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).frame(width: 19) }
                        }
                        ForEach(sorted) { row in
                            GridRow {
                                HStack(spacing: 4) {
                                    Image(systemName: row.category.icon).font(.system(size: 9)).foregroundStyle(row.category.color).frame(width: 12)
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(row.title).font(.caption2.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                                        Text(row.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                                .frame(width: 96, alignment: .leading)
                                ForEach(months) { m in
                                    if let c = row.cells[m] {
                                        MatrixCell(status: c.status(), size: 16)
                                            .onTapGesture { store.togglePaid(c); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                                    } else {
                                        Circle().fill(Color.secondary.opacity(0.08)).frame(width: 7, height: 7).frame(width: 19, height: 19)
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // fixed-width columns: text grows, the grid does not
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack(spacing: 14) {
                    key(.paid, "exp.status.paid")
                    key(.overdue, "exp.status.overdue")
                    key(.upcoming, "exp.status.upcoming")
                }
                .font(.caption2)
                Text("exp.hint").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }

            if balance.charged > 0 || balance.bills > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Label("exp.supplies.title \(String(year))", systemImage: "bolt.horizontal.circle.fill").font(.headline)
                    LabeledContent("exp.supplies.charged", value: balance.charged.money)
                    LabeledContent("exp.supplies.bills", value: (-balance.bills).money)
                    Divider()
                    LabeledContent("exp.supplies.difference") {
                        Text((balance.charged - balance.bills).signedMoney).fontWeight(.semibold)
                            .foregroundStyle(balance.charged >= balance.bills ? Color.income : Color.alert)
                    }
                    Text("exp.supplies.footer").font(.caption).foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .card()
            }
        }
    }

    private func key(_ status: CollectionStatus, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 4) { MatrixCell(status: status).scaleEffect(0.6).frame(width: 14, height: 14); Text(title).foregroundStyle(.secondary) }
    }

    // MARK: List of expenses

    private var filtered: [Expense] {
        store.data.expenses
            .filter { (activeProperty == nil || $0.propertyID == activeProperty) && (frequency == nil || $0.frequency == frequency) }
            .sorted { $0.yearlyCost > $1.yearlyCost }
    }

    private var managed: [Property] {
        store.data.properties.filter { $0.management != nil && (activeProperty == nil || $0.id == activeProperty) }
    }

    private var listView: some View {
        let upcoming = upcomingDue()
        return VStack(spacing: 14) {
            if !upcoming.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("exp.upcoming", systemImage: "calendar.badge.clock").font(.headline)
                    ForEach(upcoming.prefix(5), id: \.id) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.expense.category.icon).foregroundStyle(item.expense.category.color).frame(width: 24)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.expense.title).font(.subheadline)
                                Text("\(store.property(item.expense.propertyID)?.name ?? "") · \(item.month.title())").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.amount.money).font(.subheadline.weight(.semibold))
                        }
                    }
                }
                .card()
            }

            if !managed.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("mgmt.title", systemImage: "person.text.rectangle.fill").font(.headline)
                    ForEach(managed) { p in
                        Button { editingProperty = p } label: {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(store.managementTitle(p)).font(.subheadline).foregroundStyle(.primary)
                                    Text("\(p.name) · \(p.management.map { store.managementTerms($0) } ?? "")").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(store.managementFee(in: .current, property: p.id).money).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Text("mgmt.footer").font(.caption).foregroundStyle(.secondary)
                }
                .card()
            }

            Picker("", selection: $frequency) {
                Text("filter.every").tag(Frequency?.none)
                ForEach(Frequency.allCases) { Text($0.label).tag(Frequency?.some($0)) }
            }
            .pickerStyle(.segmented)

            if filtered.isEmpty {
                EmptyState(icon: "creditcard", title: "exp.empty.title", message: "exp.empty.message", actionTitle: "exp.add", action: { showNew = true })
            } else {
                VStack(spacing: 0) {
                    ForEach(filtered) { e in
                        Button { editing = e } label: { ExpenseRow(expense: e) }.buttonStyle(.plain)
                        if e.id != filtered.last?.id { Divider().padding(.leading, 50) }
                    }
                }
                .padding(.vertical, 4).padding(.horizontal, 12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private struct Due: Identifiable { let expense: Expense; let month: MonthKey; let amount: Double; var id: String { "\(expense.id)\(month.id)" } }

    /// Non-monthly expenses falling due in the next 6 months and not paid yet.
    private func upcomingDue() -> [Due] {
        var out: [Due] = []
        for e in store.data.expenses where e.frequency != .monthly && (activeProperty == nil || e.propertyID == activeProperty) {
            for i in 0..<6 {
                let m = MonthKey.current.adding(i)
                let a = e.amount(in: m)
                if a > 0 && !e.paidMonths.contains(m) { out.append(Due(expense: e, month: m, amount: a)) }
            }
        }
        return out.sorted { ($0.month, $0.expense.title) < ($1.month, $1.expense.title) }
    }
}

/// One charge in the month checklist: tap the circle to mark it paid, the row to edit.
private struct ChargeRow: View {
    @Environment(RentalStore.self) private var store
    let charge: Charge
    var showsMonth = false
    let onOpen: () -> Void
    let onActual: () -> Void

    var body: some View {
        let status = charge.status()
        HStack(spacing: 12) {
            Button {
                store.togglePaid(charge)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                MatrixCell(status: status).scaleEffect(1.5).frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(charge.isPaid ? "exp.unmark" : "exp.mark_paid"))
            .contextMenu { menu }

            Button(action: onOpen) {
                HStack(spacing: 12) {
                    Image(systemName: charge.category.icon).font(.footnote).foregroundStyle(charge.category.color).frame(width: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(charge.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(charge.amount.moneyExact).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        if charge.isActual, charge.planned > 0 {
                            let delta = (charge.amount / charge.planned - 1) * 100
                            Text("exp.actual_delta \(delta.formatted(.number.precision(.fractionLength(0)).sign(strategy: .always())))")
                                .font(.caption2).foregroundStyle(delta > 0.5 ? Color.alert : (delta < -0.5 ? Color.income : .secondary))
                        }
                        switch status {
                        case .paid: Pill(text: "exp.status.paid", color: .income)
                        case .overdue: Pill(text: "exp.status.overdue", color: .alert)
                        default: Pill(text: "exp.status.upcoming", color: .gray)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu { menu }
        }
    }

    @ViewBuilder private var menu: some View {
        if case .expense = charge.source {
            Button(action: onActual) { Label("exp.actual.open", systemImage: "doc.text.magnifyingglass") }
        }
        Button { store.togglePaid(charge) } label: {
            Label(charge.isPaid ? "exp.unmark" : "exp.mark_paid", systemImage: charge.isPaid ? "arrow.uturn.backward" : "checkmark.circle")
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if showsMonth { parts.append(charge.month.title()) }
        switch charge.source {
        case .expense(let id):
            if showsMonth { parts.append(store.property(charge.propertyID)?.name ?? "") }
            else if let e = store.data.expenses.first(where: { $0.id == id }) { parts.append(e.frequency.name) }
        case .management(let id):
            if let m = store.property(id)?.management { parts.append(store.managementTerms(m)) }
        }
        return parts.joined(separator: " · ")
    }
}

/// Records what the bill of one month really was; alerts compare it with the previous ones.
private struct ActualBillSheet: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let charge: Charge
    @State private var amount: Double

    init(charge: Charge) {
        self.charge = charge
        _amount = State(initialValue: charge.amount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("exp.property", value: store.property(charge.propertyID)?.name ?? "")
                    LabeledContent("exp.category") { Text(charge.title) }
                    LabeledContent("coll.month", value: charge.month.title())
                    LabeledContent("exp.planned", value: charge.planned.moneyExact)
                }
                Section {
                    MoneyField("exp.actual", value: $amount)
                    if charge.planned > 0, amount > 0 {
                        let delta = (amount / charge.planned - 1) * 100
                        LabeledContent("exp.actual.vs_plan") {
                            Text(delta.formatted(.number.precision(.fractionLength(0...1)).sign(strategy: .always())) + " %")
                                .foregroundStyle(delta > 0.5 ? Color.alert : (delta < -0.5 ? Color.income : .secondary))
                        }
                    }
                } footer: { Text("exp.actual.footer") }
                if charge.isActual {
                    Section { Button("exp.actual.clear", role: .destructive) { save(nil) } }
                }
            }
            .navigationTitle("exp.actual.open")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("common.save") { save(amount) }.disabled(amount <= 0) }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save(_ value: Double?) {
        if case .expense(let id) = charge.source { store.setActual(value, expense: id, month: charge.month) }
        dismiss()
    }
}

private struct ExpenseRow: View {
    @Environment(RentalStore.self) private var store
    let expense: Expense
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.icon).foregroundStyle(.white).frame(width: 32, height: 32)
                .background(expense.category.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text("\(store.property(expense.propertyID)?.name ?? "") · \(expense.frequency.name)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount.moneyExact).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                if expense.frequency != .annual && expense.frequency != .once {
                    Text("exp.per_year \(expense.yearlyCost.money)").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Form

struct ExpenseFormView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Expense
    @State private var isNew: Bool
    @State private var titleEdited = false
    @State private var hasEnd: Bool
    @State private var firstDate: Date
    @State private var lastDate: Date
    /// New expenses only: everything due up to this month is already paid.
    @State private var paidSoFar = true

    init(expense: Expense?, defaultProperty: UUID?) {
        let store = RentalStore.shared
        let base = expense ?? Expense(propertyID: defaultProperty ?? store.data.properties.first?.id ?? UUID(), unitID: nil,
                                      category: .community, title: "", amount: 0, frequency: ExpenseCategory.community.defaultFrequency, firstMonth: .current)
        _draft = State(initialValue: base)
        _isNew = State(initialValue: expense == nil)
        _titleEdited = State(initialValue: expense != nil)
        _hasEnd = State(initialValue: base.lastMonth != nil)
        _firstDate = State(initialValue: base.firstMonth.start)
        _lastDate = State(initialValue: (base.lastMonth ?? base.firstMonth.adding(12)).start)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(ExpenseCategory.allCases) { c in
                            Button { select(c) } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: c.icon).font(.title3)
                                        .foregroundStyle(draft.category == c ? .white : c.color)
                                        .frame(width: 40, height: 40)
                                        .background(draft.category == c ? c.color : c.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    Text(c.label).font(.caption2).foregroundStyle(.primary).lineLimit(2).minimumScaleFactor(0.8).multilineTextAlignment(.center).frame(minHeight: 24, alignment: .top)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                } header: { Text("exp.category") } footer: { if draft.category == .manager { Text("exp.manager_hint") } }
                Section {
                    TextField("form.name", text: Binding(get: { draft.title }, set: { draft.title = $0; titleEdited = true }))
                    Picker("exp.property", selection: $draft.propertyID) {
                        ForEach(store.data.properties) { Text($0.name).tag($0.id) }
                    }
                    Picker("exp.applies_to", selection: $draft.unitID) {
                        Text("exp.whole_property").tag(UUID?.none)
                        ForEach(store.units(of: draft.propertyID)) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                }
                Section {
                    MoneyField("exp.amount", value: $draft.amount)
                    Picker("exp.frequency", selection: $draft.frequency) {
                        ForEach(Frequency.allCases) { Text($0.label).tag($0) }
                    }
                    DatePicker(draft.frequency == .once ? "exp.date" : "exp.starts", selection: $firstDate, displayedComponents: .date)
                    if draft.frequency != .once {
                        Toggle("exp.has_end", isOn: $hasEnd)
                        if hasEnd { DatePicker("exp.ends", selection: $lastDate, displayedComponents: .date) }
                    }
                } footer: { if draft.frequency == .quarterly || draft.frequency == .annual { Text("exp.repeat.footer") } }
                if isNew {
                    Section {
                        Toggle(draft.frequency == .once ? "exp.paid_once" : "exp.paid_so_far", isOn: $paidSoFar)
                    } footer: { Text("exp.paid.footer") }
                }
                if !isNew {
                    Section { Button("common.delete", role: .destructive) { store.deleteExpense(draft.id); dismiss() } }
                }
            }
            .navigationTitle(isNew ? "exp.add" : "exp.edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { commit() }.disabled(draft.amount <= 0 || draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { if isNew && draft.title.isEmpty { draft.title = draft.category.name } }
        }
    }

    private func select(_ c: ExpenseCategory) {
        draft.category = c
        draft.frequency = c.defaultFrequency
        if !titleEdited { draft.title = c.name }
    }

    private func commit() {
        draft.firstMonth = MonthKey(firstDate)
        draft.lastMonth = (hasEnd && draft.frequency != .once) ? MonthKey(lastDate) : nil
        if isNew && paidSoFar { draft.paidMonths.formUnion(draft.dueMonths(through: .current)) }
        store.save(draft)
        dismiss()
    }
}
