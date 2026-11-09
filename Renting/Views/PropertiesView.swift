//
//  PropertiesView.swift
//  Renting
//
//  Homes → rooms/units → occupancy, and the tenants list as a second segment. Each
//  home shows at a glance which rooms are let and whether this month's rent is in.
//

import SwiftUI

struct PropertiesView: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui
    @State private var showNew = false
    @State private var showNewTenant = false
    /// The free plan's homes are used up: the plan opens instead of the new-home sheet.
    @State private var showLimit = false

    var body: some View {
        @Bindable var ui = ui
        NavigationStack(path: $ui.homesPath) {
            Group {
                switch ui.homesSegment {
                case .homes: homes
                case .tenants: TenantsList()
                }
            }
            .navigationTitle(ui.homesSegment == .homes ? "tab.properties" : "tab.tenants")
            .navigationDestination(for: HomesRoute.self) { route in
                switch route {
                case .property(let id): PropertyDetailView(propertyID: id)
                case .unit(let id): UnitDetailView(unitID: id)
                case .tenant(let id): TenantDetailView(tenantID: id)
                case .expenses(let id): ExpensesView(propertyFilter: id)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if ui.homesSegment == .homes {
                        Button { requestNewHome() } label: { Image(systemName: "plus") }.accessibilityLabel(Text("props.add"))
                    } else {
                        Button { showNewTenant = true } label: { Image(systemName: "person.badge.plus") }.accessibilityLabel(Text("tenant.add"))
                            .disabled(store.data.units.isEmpty)
                    }
                }
            }
            .withSettingsButton()
            .onAppear { runPendingSetup() }
            .onChange(of: ui.pendingSetup) { _, _ in runPendingSetup() }
            .sheet(isPresented: $showNew) { PropertyFormView(property: nil) }
            .sheet(isPresented: $showLimit) { ProSheet { ProPaywallView(reason: "plan.homes.reason \(Plan.freeHomeLimit)") } }
            .sheet(isPresented: $showNewTenant) {
                if let unit = store.data.units.first {
                    TenantFormView(tenant: Tenant.starting(in: unit), isNew: true)
                }
            }
            .bannerInset(.properties)
        }
    }

    /// A "get started" button elsewhere asked for the new-home or the new-tenant sheet.
    private func runPendingSetup() {
        guard let step = ui.pendingSetup else { return }
        ui.pendingSetup = nil
        switch step {
        case .addHome: requestNewHome()
        case .addTenant: if !store.data.units.isEmpty { showNewTenant = true }
        }
    }

    /// The new-home sheet, or the plan when the free homes are used up.
    private func requestNewHome() {
        if store.canAddHome { showNew = true } else { showLimit = true }
    }

    private var homes: some View {
        ScrollView {
            VStack(spacing: 12) {
                HomesSegmentPicker()
                if store.isEmpty { EmptyState(icon: "building.2", title: "props.empty.title", message: "props.empty.message") }
                ForEach(store.data.properties) { p in
                    NavigationLink(value: HomesRoute.property(p.id)) { PropertyCard(property: p) }
                        .buttonStyle(.plain)
                }
                if !store.canAddHome && !store.isEmpty {
                    Button { showLimit = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill").foregroundStyle(Color.gold)
                            Text("plan.homes.full \(Plan.freeHomeLimit)").font(.footnote.weight(.semibold)).multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.forward").font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// "Homes | Tenants" switch at the top of the Homes tab.
struct HomesSegmentPicker: View {
    @Environment(AppUI.self) private var ui
    var body: some View {
        @Bindable var ui = ui
        Picker("", selection: $ui.homesSegment) {
            Text("tab.properties").tag(HomesSegment.homes)
            Text("tab.tenants").tag(HomesSegment.tenants)
        }
        .pickerStyle(.segmented)
    }
}

private struct PropertyCard: View {
    @Environment(RentalStore.self) private var store
    let property: Property

    var body: some View {
        let units = store.units(of: property.id)
        let occ = store.occupied(property.id)
        let monthly = store.totals(in: .current, property: property.id)
        let statuses = units.compactMap { store.currentTenant(of: $0.id) }.map { store.status(of: $0, in: .current) }
        let late = statuses.filter { $0 == .overdue || $0 == .partial }.count
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: property.kind.icon).foregroundStyle(.white).frame(width: 38, height: 38)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(property.name).font(.headline).foregroundStyle(.primary)
                    Text(property.city).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Pill(text: property.kind.label, color: .brand)
            }
            HStack(spacing: 6) {
                ForEach(units) { u in
                    UnitBlock(status: store.currentTenant(of: u.id).map { store.status(of: $0, in: .current) })
                }
            }
            if !units.contains(where: { !store.tenants(of: $0.id).isEmpty }) {
                Label("home.first_tenant_hint", systemImage: "person.badge.plus").font(.footnote.weight(.semibold)).foregroundStyle(Color.brand)
            }
            HStack(spacing: 8) {
                Text("props.occupied \(occ.occupied) \(occ.total)").font(.footnote).foregroundStyle(.secondary)
                if late > 0 {
                    Pill(text: "props.late \(late)", color: .alert)
                } else if !statuses.isEmpty && statuses.allSatisfy({ $0 == .paid }) {
                    Pill(text: "props.all_paid", color: .income)
                }
                Spacer()
                Text(monthly.expected.money).font(.footnote.weight(.semibold)).foregroundStyle(.primary)
                Text("props.per_month").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

/// One room in a home card: vacant, or let with this month's rent status.
private struct UnitBlock: View {
    let status: CollectionStatus?

    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(fill)
            .overlay(Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(foreground))
            .frame(height: 26)
    }

    private var fill: Color {
        switch status {
        case nil: Color.gold.opacity(0.35)
        case .paid: Color.income
        case .partial: Color.expense
        case .overdue: Color.alert
        case .upcoming: Color.income.opacity(0.25)
        }
    }

    private var icon: String {
        switch status {
        case nil: "door.left.hand.open"
        case .paid: "checkmark"
        case .partial: "circle.lefthalf.filled"
        case .overdue: "exclamationmark"
        case .upcoming: "person.fill"
        }
    }

    private var foreground: Color {
        switch status {
        case nil: Color.gold
        case .upcoming: Color.income
        default: .white
        }
    }
}

struct EmptyState: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    /// A button that does what the message asks for.
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(Color.brand.opacity(0.6))
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) { Label(actionTitle, systemImage: "plus").fontWeight(.semibold) }
                    .buttonStyle(.borderedProminent).controlSize(.large).padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 50)
    }
}

// MARK: - Property detail

struct PropertyDetailView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let propertyID: UUID
    /// The copy being edited in place (see `AutoSave`).
    @State private var draft: Property
    @State private var flushTick = 0
    @State private var showAddUnit = false
    @State private var firstTenantRoom: Unit?
    @State private var confirmDelete = false

    init(propertyID: UUID) {
        self.propertyID = propertyID
        _draft = State(initialValue: RentalStore.shared.property(propertyID) ?? Property(name: "", address: "", city: "", kind: .traditional))
    }

    var body: some View {
        if let stored = store.property(propertyID) {
            let property = draft
            let year = store.totals(year: MonthKey.current.year, property: propertyID)
            List {
                Section {
                    HStack {
                        KPI(title: "dash.collected", value: year.collected.money, color: .income)
                        KPI(title: "dash.expenses", value: year.expenses.money, color: .expense)
                        KPI(title: "dash.net_year_short", value: year.net.signedMoney, color: year.net >= 0 ? .income : .alert)
                    }
                }
                // Nobody lives here yet: the next step is one tap away.
                if let room = store.units(of: propertyID).first, store.units(of: propertyID).allSatisfy({ store.tenants(of: $0.id).isEmpty }) {
                    Section {
                        Button { flushTick += 1; firstTenantRoom = room } label: {
                            Label("home.add_first_tenant", systemImage: "person.badge.plus").fontWeight(.semibold)
                        }
                    }
                }
                PropertyIdentitySection(property: $draft)
                PropertyKindSection(property: $draft)
                Section(property.kind == .rooms ? "props.rooms" : "props.unit") {
                    ForEach(store.units(of: propertyID)) { u in
                        NavigationLink(value: HomesRoute.unit(u.id)) { UnitRow(unit: u) }
                    }
                    if property.kind == .rooms {
                        Button { flushTick += 1; showAddUnit = true } label: { Label("props.add_room", systemImage: "plus.circle.fill") }
                    }
                }
                let recent = store.units(of: propertyID).compactMap { u in (store.currentTenant(of: u.id) ?? store.tenants(of: u.id).first).map { (u, $0) } }
                if !recent.isEmpty {
                    Section {
                        ForEach(recent, id: \.0.id) { u, t in
                            PaymentStripRow(tenant: t, title: property.kind == .rooms ? u.name : t.name, subtitle: property.kind == .rooms ? t.name : nil)
                        }
                    } header: { Text("props.collections") } footer: { Text("props.collections.footer") }
                }
                PropertyManagementSection(property: $draft) {
                    if property.management != nil {
                        LabeledContent("mgmt.fee_month", value: store.managementFee(in: .current, property: propertyID).moneyExact)
                    }
                }
                PropertyFiscalSection(property: $draft)
                Section("props.expenses") {
                    NavigationLink(value: HomesRoute.expenses(propertyID)) {
                        Label("props.see_expenses", systemImage: "creditcard.fill")
                    }
                }
                Section("form.notes") { TextField("form.notes", text: $draft.notes, axis: .vertical).lineLimit(2...8) }
                Section {
                    Button("props.delete", role: .destructive) { confirmDelete = true }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .navigationTitle(property.name)
            .navigationBarTitleDisplayMode(.inline)
            .autoSave($draft, stored: stored, flush: flushTick) { value in
                // A deleted home must not come back, and a home needs a name.
                guard store.property(value.id) != nil, !value.name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                store.save(value)
            }
            .sheet(isPresented: $showAddUnit) { UnitFormView(unit: Unit(propertyID: propertyID, name: "", listRent: 0)) }
            .sheet(item: $firstTenantRoom) { TenantFormView(tenant: Tenant.starting(in: $0), isNew: true) }
            .confirmationDialog("props.delete.confirm", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("props.delete", role: .destructive) { store.deleteProperty(propertyID); dismiss() }
            } message: { Text("props.delete.message") }
            .countsAsBreakpoint()
        }
    }
}

private struct UnitRow: View {
    @Environment(RentalStore.self) private var store
    let unit: Unit
    var body: some View {
        let tenant = store.currentTenant(of: unit.id)
        HStack(spacing: 12) {
            Circle().fill(tenant != nil ? Color.income : Color.gold).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(unit.name).font(.body)
                Text(tenant?.name ?? L("unit.vacant")).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text((tenant?.monthlyTotal(in: .current) ?? unit.listRent).money).font(.subheadline.weight(.semibold))
                Pill(text: tenant != nil ? "unit.occupied" : "unit.vacant", color: tenant != nil ? .income : .gold)
            }
        }
    }
}

// MARK: - Unit detail

struct UnitDetailView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let unitID: UUID
    @State private var draft: Unit
    @State private var flushTick = 0
    @State private var showNewTenant = false
    @State private var confirmDelete = false

    init(unitID: UUID) {
        self.unitID = unitID
        _draft = State(initialValue: RentalStore.shared.unit(unitID) ?? Unit(propertyID: UUID(), name: "", listRent: 0))
    }

    var body: some View {
        if let stored = store.unit(unitID) {
            let tenants = store.tenants(of: unitID)
            List {
                Section {
                    TextField("form.name", text: $draft.name)
                    MoneyField("unit.list_rent", value: $draft.listRent)
                    MoneyField("unit.expenses", value: Binding(get: { draft.listExpenses ?? 0 }, set: { draft.listExpenses = $0 > 0 ? $0 : nil }))
                    MoneyField("form.sqm", value: Binding(get: { draft.sqm ?? 0 }, set: { draft.sqm = $0 > 0 ? $0 : nil }), isMoney: false)
                    if let p = store.property(draft.propertyID) { LabeledContent("unit.property", value: p.name) }
                } footer: { Text("unit.price_note") }
                Section("unit.tenants") {
                    ForEach(tenants) { t in
                        NavigationLink(value: HomesRoute.tenant(t.id)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.name)
                                    Text(t.exitDate == nil ? "\(t.entryDate.short) →" : "\(t.entryDate.short) → \(t.exitDate!.short)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    // What this tenant pays: the room's price changes from tenant to tenant.
                                    Text("coll.rent_plus \(t.monthlyRent.money) \(t.monthlyExpenses.money)").font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if t.isActive { Pill(text: "tenant.active", color: .income) } else { Pill(text: "tenant.left", color: .gray) }
                            }
                        }
                    }
                    Button { flushTick += 1; showNewTenant = true } label: { Label("tenant.add", systemImage: "person.badge.plus") }
                }
                Section { Button("unit.delete", role: .destructive) { confirmDelete = true } }
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .navigationTitle(draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .autoSave($draft, stored: stored, flush: flushTick) { value in
                guard store.unit(value.id) != nil, !value.name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                store.save(value)
            }
            .sheet(isPresented: $showNewTenant) {
                TenantFormView(tenant: Tenant.starting(in: draft), isNew: true)
            }
            .confirmationDialog("unit.delete.confirm", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("unit.delete", role: .destructive) { store.deleteUnit(unitID); dismiss() }
            }
            .countsAsBreakpoint()
        }
    }
}

// MARK: - Sections shared by the detail screen and the "new home" sheet

struct PropertyIdentitySection: View {
    @Binding var property: Property
    /// Why the sheet cannot be saved yet, shown under the fields.
    var hint: LocalizedStringKey?

    var body: some View {
        Section {
            TextField("form.name", text: $property.name)
            TextField("form.address", text: $property.address)
            TextField("form.city", text: $property.city)
        } footer: { if let hint { Text(hint).foregroundStyle(Color.expense) } }
    }
}

struct PropertyKindSection: View {
    @Binding var property: Property
    var body: some View {
        Section {
            Picker("form.kind", selection: $property.kind) {
                ForEach(RentalKind.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
            }
        } footer: { Text(property.kind.footer) }
    }
}

/// The manager or agency charging a percentage of the rent.
struct PropertyManagementSection<Extra: View>: View {
    @Binding var property: Property
    @ViewBuilder var extra: () -> Extra

    var body: some View {
        Section {
            SubscriberRows {
                Toggle("mgmt.has", isOn: Binding(
                    get: { property.management != nil },
                    set: { property.management = $0 ? (property.management ?? Management(percent: 8)) : nil }))
                if property.management != nil {
                    TextField("mgmt.name", text: Binding(get: { property.management?.name ?? "" }, set: { property.management?.name = $0 }))
                    MoneyField("mgmt.percent", value: Binding(get: { property.management?.percent ?? 0 }, set: { property.management?.percent = $0 }), suffix: "%")
                    Toggle("mgmt.plus_vat", isOn: Binding(get: { property.management?.plusVAT ?? false }, set: { property.management?.plusVAT = $0 }))
                }
            }
            extra()
        } header: { Text("mgmt.title") } footer: { Text("mgmt.form.footer") }
    }
}

extension PropertyManagementSection where Extra == EmptyView {
    init(property: Binding<Property>) { self.init(property: property, extra: { EmptyView() }) }
}

/// Values the fiscal report needs: depreciation and the income imputed for the days the home is empty.
struct PropertyFiscalSection: View {
    @Binding var property: Property
    var body: some View {
        Section {
            SubscriberRows {
                MoneyField("form.construction_value", value: Binding(get: { property.constructionValue ?? 0 }, set: { property.constructionValue = $0 > 0 ? $0 : nil }))
                MoneyField("form.cadastral_value", value: Binding(get: { property.cadastralValue ?? 0 }, set: { property.cadastralValue = $0 > 0 ? $0 : nil }))
                Toggle("form.cadastral_revised", isOn: $property.cadastralRevised)
                Toggle("form.owner_residence", isOn: $property.ownerResidence)
            }
        } header: { Text("form.fiscal") } footer: { Text("form.fiscal.footer") }
    }
}

// MARK: - New home and new room

/// One room being set up in the "new home" sheet: each has its own rent and utilities contribution.
private struct RoomDraft: Identifiable {
    let id = UUID()
    var name: String
    var rent = 0.0
    var expenses = 0.0
}

/// The sheet for adding a home (with its rooms). Opened with an existing home it edits the home from
/// the Fiscal and Expenses tabs; on its own detail screen a home is edited in place.
struct PropertyFormView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Property
    @State private var isNew: Bool
    @State private var rooms: [RoomDraft]
    @State private var unitRent = 0.0
    @State private var unitExpenses = 0.0

    init(property: Property?) {
        // A whole home is the common case; "by rooms" is one choice away and brings the rooms with it.
        _draft = State(initialValue: property ?? Property(name: "", address: "", city: "", kind: .traditional))
        _isNew = State(initialValue: property == nil)
        _rooms = State(initialValue: (1...3).map { RoomDraft(name: L("unit.room_n", $0)) })
    }

    /// A new room starts with the price of the one before it: the landlord changes what differs.
    private func resize(_ count: Int) {
        while rooms.count < count {
            let last = rooms.last
            rooms.append(RoomDraft(name: L("unit.room_n", rooms.count + 1), rent: last?.rent ?? 0, expenses: last?.expenses ?? 0))
        }
        if rooms.count > count { rooms.removeLast(rooms.count - count) }
    }

    var body: some View {
        NavigationStack {
            Form {
                PropertyIdentitySection(property: $draft, hint: draft.name.trimmingCharacters(in: .whitespaces).isEmpty ? "form.name_required" : nil)
                PropertyKindSection(property: $draft)
                if isNew && draft.kind == .rooms {
                    Section {
                        Stepper("form.room_count \(rooms.count)", value: Binding(get: { rooms.count }, set: resize), in: 1...20)
                    } footer: { Text("form.rooms.footer") }
                    ForEach($rooms) { $room in
                        Section {
                            TextField("form.name", text: $room.name)
                            MoneyField("form.monthly_rent", value: $room.rent)
                            MoneyField("unit.expenses", value: $room.expenses)
                        }
                    }
                } else if isNew {
                    Section {
                        MoneyField("form.monthly_rent", value: $unitRent)
                        MoneyField("unit.expenses", value: $unitExpenses)
                    } footer: { Text("form.units.footer") }
                }
                PropertyManagementSection(property: $draft)
                PropertyFiscalSection(property: $draft)
                Section("form.notes") { TextField("form.notes", text: $draft.notes, axis: .vertical).lineLimit(2...5) }
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .navigationTitle(isNew ? "props.add" : "props.edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { commit() }.disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func commit() {
        if let m = draft.management, m.percent <= 0 { draft.management = nil }
        guard isNew else { store.save(draft); dismiss(); return }
        let units: [Unit]
        if draft.kind == .rooms {
            units = rooms.enumerated().map { i, r in
                let name = r.name.trimmingCharacters(in: .whitespaces)
                return Unit(propertyID: draft.id, name: name.isEmpty ? L("unit.room_n", i + 1) : name, listRent: r.rent, listExpenses: r.expenses > 0 ? r.expenses : nil)
            }
        } else {
            units = [Unit(propertyID: draft.id, name: L("unit.whole"), listRent: unitRent, listExpenses: unitExpenses > 0 ? unitExpenses : nil)]
        }
        store.save(draft, units: units)
        dismiss()
    }
}

/// The sheet for adding a room to a home. An existing room is edited in place on its detail screen.
struct UnitFormView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var unit: Unit

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("form.name", text: $unit.name)
                    MoneyField("unit.list_rent", value: $unit.listRent)
                    MoneyField("unit.expenses", value: Binding(get: { unit.listExpenses ?? 0 }, set: { unit.listExpenses = $0 > 0 ? $0 : nil }))
                    MoneyField("form.sqm", value: Binding(get: { unit.sqm ?? 0 }, set: { unit.sqm = $0 > 0 ? $0 : nil }), isMoney: false)
                } footer: { Text("unit.price_note") }
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .navigationTitle("props.add_room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { store.save(unit); dismiss() }.disabled(unit.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// Number field with a leading label; used for money, areas and percentages.
struct MoneyField: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    var isMoney = true
    /// Unit shown instead of the currency symbol ("%").
    var suffix: String?

    init(_ title: LocalizedStringKey, value: Binding<Double>, isMoney: Bool = true) {
        self.title = title
        self._value = value
        self.isMoney = isMoney
    }

    init(_ title: LocalizedStringKey, value: Binding<Double>, suffix: String) {
        self.init(title, value: value, isMoney: false)
        self.suffix = suffix
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            // The decimal pad shows the separator of the device's region, so that is what must be read:
            // with the app's language, "12,5" typed in an English app was read as 12.
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)).locale(Locale.current))
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 120)
            if isMoney { Text(Locale(identifier: "en@currency=\(AppCurrency.shared.code)").currencySymbol ?? "").foregroundStyle(.secondary) }
            else if let suffix { Text(suffix).foregroundStyle(.secondary) }
        }
    }
}
