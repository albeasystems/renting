//
//  TenantsView.swift
//  Renting
//
//  Tenants tied to a home/room: deposit (fianza), extra guarantee, what they pay in
//  rent and utilities, move-in and move-out dates, the deposit return and the payment
//  history. The list lives as the second segment of the Homes tab. The detail screen is edited
//  in place (see `AutoSave`); the "new tenant" sheet uses the same field sections.
//

import SwiftUI

struct TenantsList: View {
    @Environment(RentalStore.self) private var store
    @State private var search = ""

    private var filtered: [Tenant] {
        store.data.tenants.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || store.unitLabel($0).localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            let active = filtered.filter(\.isActive).sorted { store.unitLabel($0) < store.unitLabel($1) }
            let past = filtered.filter { !$0.isActive }.sorted { ($0.exitDate ?? .distantPast) > ($1.exitDate ?? .distantPast) }
            Section { HomesSegmentPicker() }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            if store.data.tenants.isEmpty {
                EmptyState(icon: "person.2", title: "tenants.empty.title", message: "tenants.empty.message").listRowBackground(Color.clear)
            }
            if !active.isEmpty {
                Section("tenants.active") { ForEach(active) { row($0) } }
            }
            if !past.isEmpty {
                Section("tenants.past") { ForEach(past) { row($0) } }
            }
        }
        .searchable(text: $search)
    }

    private func row(_ t: Tenant) -> some View {
        NavigationLink(value: HomesRoute.tenant(t.id)) {
            HStack(spacing: 12) {
                Text(String(t.name.prefix(1))).font(.headline).foregroundStyle(.white).frame(width: 38, height: 38)
                    .background(t.isActive ? Color.brand : Color.gray, in: Circle())
                    .overlay(alignment: .bottomTrailing) {
                        if t.isActive { MatrixCell(status: store.status(of: t, in: .current), size: 12).background(Color(.secondarySystemGroupedBackground), in: Circle()).offset(x: 4, y: 4) }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name).font(.body)
                    Text(store.unitLabel(t)).font(.caption).foregroundStyle(.secondary)
                    if let left = store.contractEndDays(t) {
                        Pill(text: left < 0 ? "tenant.contract_expired" : "tenant.ends_in \(left)", color: left <= 30 ? .alert : .gold)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(t.monthlyTotal(in: .current).money).font(.subheadline.weight(.semibold))
                    if t.exitDate != nil && t.depositReturned == nil && t.deposit > 0 { Pill(text: "tenant.deposit_pending", color: .gold) }
                }
            }
        }
    }
}

// MARK: - Detail

struct TenantDetailView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let tenantID: UUID
    /// The copy being edited (see `AutoSave`).
    @State private var draft: Tenant
    @State private var flushTick = 0
    @State private var showReturn = false
    @State private var showExit = false
    @State private var confirmDelete = false
    @State private var receipt: CollectionsView.PartialTarget?
    @State private var updating: RentReview?
    @State private var letter: RentChange?
    @State private var confirmUndo = false

    init(tenantID: UUID) {
        self.tenantID = tenantID
        _draft = State(initialValue: RentalStore.shared.tenant(tenantID) ?? Tenant(unitID: UUID(), name: "", entryDate: Date(), monthlyRent: 0))
    }

    /// Writes pending edits, then runs the action: used before opening a sheet that saves the same tenant.
    private func present(_ action: () -> Void) {
        flushTick += 1
        action()
    }

    var body: some View {
        if let stored = store.tenant(tenantID) {
            let t = draft
            let year = MonthKey.current.year
            let row = store.summaryByTenant(year: year).first { $0.id == t.id }
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("form.name", text: $draft.name).font(.title2.bold())
                        Text(store.unitLabel(t)).font(.subheadline).foregroundStyle(.secondary)
                        HStack {
                            if t.isActive { Pill(text: "tenant.active", color: .income) } else { Pill(text: "tenant.left", color: .gray) }
                            if let left = store.contractEndDays(t) {
                                Pill(text: left < 0 ? "tenant.contract_expired" : "tenant.ends_in \(left)", color: left <= 30 ? .alert : .gold)
                            }
                        }
                    }
                    HStack {
                        TextField("form.phone", text: $draft.phone).keyboardType(.phonePad)
                        if !t.phone.isEmpty, let url = URL(string: "tel:\(t.phone.filter { $0.isNumber || $0 == "+" })") {
                            Button { openURL(url) } label: { Image(systemName: "phone.fill") }.buttonStyle(.borderless)
                        }
                    }
                    TextField("form.email", text: $draft.email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                }

                TenantPaymentsSection(tenant: $draft) {
                    LabeledContent("tenant.total_month") { Text(t.monthlyTotal(in: .current).moneyExact).fontWeight(.semibold) }
                    LabeledContent("tenant.income_year \(String(year))") { Text((row?.income ?? 0).money).foregroundStyle(Color.income).fontWeight(.semibold) }
                    if let row, row.expected - row.income > 0.5 {
                        LabeledContent("tenant.pending") { Text((row.expected - row.income).money).foregroundStyle(Color.alert) }
                    }
                }

                Section {
                    PaymentCalendar(tenant: t)
                } header: { Text("tenant.history") } footer: { Text("tenant.history.footer") }

                let paidMonths = store.tenancyMonths(t).reversed().filter { store.payment(of: t.id, in: $0) != nil }.prefix(6)
                if !paidMonths.isEmpty {
                    Section("tenant.receipts") {
                        ForEach(Array(paidMonths)) { m in
                            Button { present { receipt = .init(tenant: t, month: m) } } label: {
                                HStack {
                                    Label(m.title(), systemImage: "doc.text").foregroundStyle(.primary)
                                    Spacer()
                                    Text((store.payment(of: t.id, in: m)?.amount ?? 0).moneyExact).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                rentUpdateSection(t)

                TenantDatesSection(tenant: $draft) {
                    if t.exitDate != nil {
                        DatePicker("tenant.exit", selection: Binding(get: { draft.exitDate ?? Date() }, set: { draft.exitDate = $0 }),
                                   in: t.entryDate..., displayedComponents: .date)
                        if !t.isActive {
                            Button { draft.exitDate = nil } label: { Label("tenant.reactivate", systemImage: "arrow.uturn.backward") }
                        }
                    } else {
                        Button { present { showExit = true } } label: { Label("tenant.register_exit", systemImage: "rectangle.portrait.and.arrow.right") }
                    }
                }

                TenantContractSection(tenant: $draft)

                TenantGuaranteeSection(tenant: $draft) {
                    LabeledContent("tenant.deposit_state") { Text(stateKey(t)).foregroundStyle(stateColor(t)) }
                    let filing = store.filingInfo(for: t)
                    if filing.status != .notApplicable {
                        SubscriberRows {
                            Toggle("dep.filed", isOn: Binding(get: { draft.filing?.filedOn != nil }, set: { draft.setDeposited($0) }))
                            if t.filing?.filedOn == nil { FilingStatusText(info: filing).font(.footnote) }
                        }
                    }
                    if let returned = t.depositReturned {
                        LabeledContent("tenant.returned", value: returned.moneyExact)
                        if let d = t.depositReturnDate { LabeledContent("tenant.returned_on", value: d.short) }
                    }
                    if t.deposit > 0 {
                        Button { present { showReturn = true } } label: { Label(t.depositReturned == nil ? "tenant.register_return" : "tenant.edit_return", systemImage: "arrow.uturn.left.circle") }
                    }
                }

                TenantFiscalSection(tenant: $draft)

                Section("form.notes") { TextField("form.notes", text: $draft.notes, axis: .vertical).lineLimit(2...8) }

                Section { Button("tenant.delete", role: .destructive) { confirmDelete = true } }
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .navigationTitle(t.name)
            .navigationBarTitleDisplayMode(.inline)
            .autoSave($draft, stored: stored, flush: flushTick) { value in
                // A deleted tenant must not come back, and a tenant needs a name.
                guard store.tenant(value.id) != nil, !value.name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                store.save(value)
            }
            .sheet(isPresented: $showReturn) { DepositReturnSheet(tenant: t) }
            .sheet(isPresented: $showExit) { ExitSheet(tenant: t) }
            .sheet(item: $receipt) { ReceiptSheet(tenant: $0.tenant, month: $0.month) }
            .sheet(item: $updating) { RentUpdateSheet(review: $0) }
            .sheet(item: $letter) { RentLetterSheet(tenant: t, change: $0) }
            .confirmationDialog("upd.undo.confirm", isPresented: $confirmUndo, titleVisibility: .visible) {
                Button("upd.undo", role: .destructive) { store.undoLastRentChange(of: t) }
            } message: { Text("upd.undo.message") }
            .confirmationDialog("tenant.delete.confirm", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("tenant.delete", role: .destructive) { store.deleteTenant(tenantID); dismiss() }
            } message: { Text("tenant.delete.message") }
            .countsAsBreakpoint()
        }
    }

    /// Index of the contract (editable), next anniversary, the update button and the history of updates.
    @ViewBuilder private func rentUpdateSection(_ t: Tenant) -> some View {
        let index = store.updateIndex(for: t)
        let pending = store.pendingReview(for: t)
        let next = store.nextAnniversary(of: t)
        Section {
            SubscriberRows {
                Picker("upd.index", selection: $draft.rentIndex) {
                    Text("idx.auto \(store.automaticIndex(for: t).name)").tag(RentIndex?.none)
                    ForEach(RentIndex.allCases) { Text($0.label).tag(RentIndex?.some($0)) }
                }
                .pickerStyle(.navigationLink)
                if let future = t.changes.first(where: { $0.effective > .current }) {
                    LabeledContent("upd.future \(future.effective.title())") { Text(future.new.moneyExact).foregroundStyle(Color.brand) }
                }
                if t.isActive, index != .none, let next, !store.isSeasonal(t) {
                    LabeledContent("upd.next") { Text(next.date.short).foregroundStyle(pending != nil ? Color.gold : .secondary) }
                    let review = pending ?? RentReview(tenant: t, cycle: next.cycle, anniversary: next.date,
                                                       daysToAnniversary: store.daysToDeadline(next.date))
                    Button { present { updating = review } } label: { Label("upd.action", systemImage: "chart.line.uptrend.xyaxis") }
                }
                if index == .none && t.isActive { Text("upd.no_clause").font(.footnote).foregroundStyle(.secondary) }
                ForEach(t.changes.reversed()) { c in
                    Button { if c.percent > 0 { present { letter = c } } } label: {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: "\(c.previous.moneyExact) → \(c.new.moneyExact)").foregroundStyle(.primary)
                                Text(verbatim: c.percent > 0 ? "+\(c.percent.percentText) · \(c.index.name)" : L("upd.kept")).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(c.effective.title(short: true)).font(.footnote).foregroundStyle(.secondary)
                            if c.percent > 0 { Image(systemName: "doc.text").font(.footnote).foregroundStyle(Color.brand) }
                        }
                    }
                }
                if !t.changes.isEmpty {
                    Button("upd.undo", role: .destructive) { present { confirmUndo = true } }.font(.footnote)
                }
            }
        } header: { Text("upd.section") } footer: { Text("upd.section.footer") }
    }

    private func stateKey(_ t: Tenant) -> LocalizedStringKey {
        switch t.depositState {
        case .held: "deposit.held"
        case .returned: "deposit.returned"
        case .partial: "deposit.partial"
        case .withheld: "deposit.withheld"
        }
    }

    private func stateColor(_ t: Tenant) -> Color {
        switch t.depositState {
        case .held: t.isActive ? .secondary : .gold
        case .returned: .income
        case .partial: .expense
        case .withheld: .alert
        }
    }
}

// MARK: - Sections shared by the detail screen and the "new tenant" sheet

/// Rent and utilities the tenant pays each month. This is the tenant's own price: the room's asking
/// price is only where it starts, and changing it later does not touch a tenant who is already in.
struct TenantPaymentsSection<Extra: View>: View {
    @Binding var tenant: Tenant
    @ViewBuilder var extra: () -> Extra

    var body: some View {
        Section {
            MoneyField("tenant.rent", value: $tenant.monthlyRent)
            MoneyField("tenant.expenses", value: $tenant.monthlyExpenses)
            extra()
        } header: { Text("tenant.payments") } footer: { Text("tenant.expenses.footer") }
    }
}

extension TenantPaymentsSection where Extra == EmptyView {
    init(tenant: Binding<Tenant>) { self.init(tenant: tenant, extra: { EmptyView() }) }
}

/// Room, move-in date and contract end (and, in the detail screen, the move-out).
struct TenantDatesSection<Extra: View>: View {
    @Environment(RentalStore.self) private var store
    @Binding var tenant: Tenant
    @ViewBuilder var extra: () -> Extra

    var body: some View {
        Section("tenant.dates") {
            Picker("tenant.unit", selection: $tenant.unitID) {
                ForEach(store.data.properties) { p in
                    ForEach(store.units(of: p.id)) { u in
                        Text(p.kind == .rooms ? "\(p.name) · \(u.name)" : p.name).tag(u.id)
                    }
                }
            }
            DatePicker("tenant.entry", selection: $tenant.entryDate, displayedComponents: .date)
            Toggle("tenant.has_contract_end", isOn: Binding(
                get: { tenant.contractEnd != nil },
                set: { tenant.contractEnd = $0 ? (tenant.contractEnd ?? Calendar.current.date(byAdding: .year, value: 1, to: tenant.entryDate)) : nil }))
            if let end = tenant.contractEnd {
                DatePicker("tenant.contract_end", selection: Binding(get: { end }, set: { tenant.contractEnd = $0 }), displayedComponents: .date)
            }
            extra()
        }
    }
}

extension TenantDatesSection where Extra == EmptyView {
    init(tenant: Binding<Tenant>) { self.init(tenant: tenant, extra: { EmptyView() }) }
}

/// Law, duration and rent insurance. A tenant with no contract information shows the usual values
/// for the home; nothing is stored until one of them is changed.
struct TenantContractSection: View {
    @Environment(RentalStore.self) private var store
    @Binding var tenant: Tenant

    private var usual: ContractInfo {
        let seasonal = store.property(store.propertyID(ofUnit: tenant.unitID) ?? UUID())?.kind == .seasonal
        return ContractInfo(regime: seasonal ? .lauSeasonal : .lauHousing, term: seasonal ? .shortTerm : .annual, rentInsurance: false)
    }

    var body: some View {
        let info = tenant.contract ?? usual
        Section {
            SubscriberRows {
                Picker("contract.regime", selection: Binding(get: { info.regime }, set: { v in var c = info; c.regime = v; tenant.contract = c })) {
                    ForEach(ContractRegime.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.navigationLink)
                Picker("contract.term", selection: Binding(get: { info.term }, set: { v in var c = info; c.term = v; tenant.contract = c })) {
                    ForEach(ContractTerm.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.navigationLink)
                Toggle("contract.insurance", isOn: Binding(get: { info.rentInsurance }, set: { v in var c = info; c.rentInsurance = v; tenant.contract = c }))
            }
        } header: { Text("contract.title") } footer: { Text("contract.footer") }
    }
}

/// Fianza and extra guarantee amounts (and, in the detail screen, where the deposit stands).
struct TenantGuaranteeSection<Extra: View>: View {
    @Environment(RentalStore.self) private var store
    @Binding var tenant: Tenant
    @ViewBuilder var extra: () -> Extra

    var body: some View {
        Section {
            MoneyField("tenant.deposit", value: $tenant.deposit)
            MoneyField("tenant.extra_guarantee", value: $tenant.extraGuarantee)
            extra()
        } header: { Text("tenant.guarantees") } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("tenant.extra_guarantee.footer")
                if !store.isSeasonal(tenant) && tenant.deposit > tenant.monthlyRent + 0.005 && tenant.monthlyRent > 0 { Text("deposit.hint") }
            }
        }
    }
}

extension TenantGuaranteeSection where Extra == EmptyView {
    init(tenant: Binding<Tenant>) { self.init(tenant: tenant, extra: { EmptyView() }) }
}

/// Income-tax reduction of the contract: automatic unless the landlord chooses one.
struct TenantFiscalSection: View {
    @Environment(RentalStore.self) private var store
    @Binding var tenant: Tenant

    var body: some View {
        Section {
            SubscriberRows {
                Picker("tenant.reduction", selection: $tenant.reduction) {
                    Text("red.auto \(store.automaticReduction(for: tenant).short)").tag(RentReduction?.none)
                    ForEach(RentReduction.allCases) { Text($0.label).tag(RentReduction?.some($0)) }
                }
                .pickerStyle(.navigationLink)
            }
        } header: { Text("tenant.fiscal") } footer: { Text("red.footer") }
    }
}

// MARK: - Sheets

private struct DepositReturnSheet: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tenant: Tenant
    @State private var amount: Double
    @State private var date: Date

    init(tenant: Tenant) {
        self.tenant = tenant
        _amount = State(initialValue: tenant.depositReturned ?? tenant.deposit)
        _date = State(initialValue: tenant.depositReturnDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { MoneyField("tenant.returned", value: $amount); DatePicker("tenant.returned_on", selection: $date, displayedComponents: .date) }
                footer: { Text("tenant.deposit_footer \(tenant.deposit.moneyExact) \(max(0, tenant.deposit - amount).moneyExact)") }
                if tenant.depositReturned != nil {
                    Section { Button("tenant.clear_return", role: .destructive) { var t = tenant; t.depositReturned = nil; t.depositReturnDate = nil; store.save(t); dismiss() } }
                }
            }
            .navigationTitle("tenant.register_return")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { var t = tenant; t.depositReturned = amount; t.depositReturnDate = date; store.save(t); dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct ExitSheet: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tenant: Tenant
    @State private var date: Date

    init(tenant: Tenant) {
        self.tenant = tenant
        _date = State(initialValue: max(Date(), tenant.entryDate))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Leaving before moving in would make the tenant disappear from every month.
                DatePicker("tenant.exit", selection: $date, in: tenant.entryDate..., displayedComponents: .date)
                Text("tenant.exit.footer").font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("tenant.register_exit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("common.save") { var t = tenant; t.exitDate = date; store.save(t); dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - New tenant

/// The sheet for adding a tenant. An existing tenant is edited in place on its detail screen.
struct TenantFormView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var tenant: Tenant
    let isNew: Bool

    init(tenant: Tenant, isNew: Bool) {
        var tenant = tenant
        let store = RentalStore.shared
        let seasonalHome = store.property(store.propertyID(ofUnit: tenant.unitID) ?? UUID())?.kind == .seasonal
        // A new tenant starts with the usual contract; an old one stays "not filled in" until edited.
        if isNew && tenant.contract == nil {
            tenant.contract = ContractInfo(regime: seasonalHome ? .lauSeasonal : .lauHousing, term: seasonalHome ? .shortTerm : .annual, rentInsurance: false)
        }
        _tenant = State(initialValue: tenant)
        self.isNew = isNew
    }

    /// What is still missing to save, in the order it is asked.
    private var missing: LocalizedStringKey? {
        if tenant.name.trimmingCharacters(in: .whitespaces).isEmpty { return "form.name_required" }
        if isNew && tenant.monthlyRent <= 0 { return "tenant.rent_required" }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("form.name", text: $tenant.name)
                    TextField("form.phone", text: $tenant.phone).keyboardType(.phonePad)
                    TextField("form.email", text: $tenant.email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                } footer: { if let missing { Text(missing).foregroundStyle(Color.expense) } }
                // What the tenant pays comes before the dates and the legal details: it is the one thing the app cannot do without.
                TenantPaymentsSection(tenant: $tenant)
                TenantDatesSection(tenant: $tenant)
                TenantContractSection(tenant: $tenant)
                Section {
                    SubscriberRows {
                        Picker("upd.index", selection: $tenant.rentIndex) {
                            Text("idx.auto \(store.automaticIndex(for: tenant).name)").tag(RentIndex?.none)
                            ForEach(RentIndex.allCases) { Text($0.label).tag(RentIndex?.some($0)) }
                        }
                        .pickerStyle(.navigationLink)
                    }
                } header: { Text("upd.section") } footer: { Text("upd.form.footer") }
                TenantGuaranteeSection(tenant: $tenant)
                TenantFiscalSection(tenant: $tenant)
                Section("form.notes") { TextField("form.notes", text: $tenant.notes, axis: .vertical).lineLimit(2...6) }
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            // The room's price is where a new tenant starts: choosing another room brings its rent and
            // utilities, unless the landlord already typed something different.
            .onChange(of: tenant.unitID) { old, new in
                guard isNew, let room = store.unit(new) else { return }
                let before = store.unit(old)
                if tenant.monthlyRent == 0 || tenant.monthlyRent == before?.listRent { tenant.monthlyRent = room.listRent }
                if tenant.monthlyExpenses == 0 || tenant.monthlyExpenses == (before?.listExpenses ?? 0) { tenant.monthlyExpenses = room.listExpenses ?? 0 }
            }
            .navigationTitle(isNew ? "tenant.add" : "tenant.edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        store.save(tenant)
                        dismiss()
                    }.disabled(missing != nil)
                }
            }
        }
    }
}
