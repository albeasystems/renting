//
//  CollectionsView.swift
//  Renting
//
//  The "calendar check": one tap per tenant and month marks the rent (and the utilities
//  charged on top) as collected. Month view = checklist; year view = a 12-month matrix
//  of every tenant. Also the payment calendars shown in home and tenant details.
//

import SwiftUI

struct CollectionsView: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui

    enum Mode: String, CaseIterable, Identifiable { case month, year; var id: String { rawValue } }
    @State private var mode: Mode = .month
    @State private var month = MonthKey.current
    @State private var year = MonthKey.current.year
    @State private var property: UUID?
    @State private var partial: PartialTarget?

    struct PartialTarget: Identifiable {
        let tenant: Tenant
        let month: MonthKey
        /// Opens the receipt instead of the payment editor.
        var receipt = false
        var id: String { "\(tenant.id)\(month.id)\(receipt)" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Picker("", selection: $mode) {
                        Text("period.month").tag(Mode.month)
                        Text("period.year").tag(Mode.year)
                    }.pickerStyle(.segmented)

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

                    if mode == .month { monthView } else { yearView }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("tab.collections")
            .withSettingsButton()
            #if DEBUG
            // Marketing captures only (marketing/capture.sh): `-debugYear 1` opens the 12-month matrix,
            // `-debugReceipt 1` opens the rent receipt of the first tenant who has paid this month.
            .onAppear {
                let args = ProcessInfo.processInfo.arguments
                if args.contains("-debugYear") { mode = .year }
                if args.contains("-debugReceipt") {
                    let paid = store.tenants(in: .current, property: nil).filter { store.payment(of: $0.id, in: .current) != nil }
                    if let t = paid.first(where: { $0.name.hasPrefix("Luc") }) ?? paid.first {
                        partial = PartialTarget(tenant: t, month: .current, receipt: true)
                    }
                }
            }
            #endif
            .sheet(item: $partial) { target in
                if target.receipt { ReceiptSheet(tenant: target.tenant, month: target.month) }
                else { PartialPaymentSheet(tenant: target.tenant, month: target.month) }
            }
            .bannerInset(.collections)
        }
    }

    // MARK: Month

    private var monthView: some View {
        let totals = store.totals(in: month, property: property)
        let tenants = store.tenants(in: month, property: property)
        let grouped = Dictionary(grouping: tenants) { store.propertyID(ofTenant: $0) ?? UUID() }
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
                    Text("coll.progress").font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(totals.collected.money) / \(totals.expected.money)").font(.subheadline.weight(.semibold))
                }
                ProgressView(value: totals.collected, total: max(totals.expected, 1)).tint(Color.income)
                if totals.pending > 0 {
                    HStack {
                        Text("coll.pending \(totals.pending.money)").font(.footnote).foregroundStyle(Color.alert)
                        Spacer()
                        Button("coll.mark_all") { markAll(tenants) }.font(.footnote.weight(.semibold))
                    }
                }
            }
            .card()

            if tenants.isEmpty {
                if store.setupStep != nil { SetupPrompt() }
                else { EmptyState(icon: "checkmark.circle", title: "coll.empty.title", message: "coll.empty.message") }
            }

            ForEach(store.data.properties.filter { grouped[$0.id] != nil }) { p in
                VStack(alignment: .leading, spacing: 0) {
                    Text(p.name).font(.footnote.weight(.semibold)).foregroundStyle(.secondary).padding(.bottom, 8)
                    ForEach(grouped[p.id] ?? []) { t in
                        CollectionRow(tenant: t, month: month,
                                      onPartial: { partial = PartialTarget(tenant: t, month: month) },
                                      onReceipt: { partial = PartialTarget(tenant: t, month: month, receipt: true) })
                        if t.id != grouped[p.id]?.last?.id { Divider().padding(.vertical, 6) }
                    }
                }
                .card()
            }
        }
    }

    private func markAll(_ tenants: [Tenant]) {
        for t in tenants where store.payment(of: t.id, in: month) == nil { store.togglePayment(t, month: month) }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: Year matrix

    private var yearView: some View {
        let months = MonthKey.months(of: year)
        let tenants = store.data.tenants
            .filter { t in months.contains { t.isActive(in: $0) } && (property == nil || store.propertyID(ofTenant: t) == property) }
            .sorted { store.unitLabel($0) < store.unitLabel($1) }
        return VStack(spacing: 14) {
            HStack {
                Button { year -= 1 } label: { Image(systemName: "chevron.backward") }
                Spacer()
                Text(String(year)).font(.headline)
                Spacer()
                Button { year += 1 } label: { Image(systemName: "chevron.forward") }
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                    GridRow {
                        Text("").frame(width: 76)
                        ForEach(months) { m in Text(m.monthName(narrow: true)).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).frame(width: 28) }
                    }
                    ForEach(tenants) { t in
                        GridRow {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(t.name).font(.caption2.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                                Text(store.unitLabel(t)).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }.frame(width: 76, alignment: .leading)
                            ForEach(months) { m in
                                if t.isActive(in: m) {
                                    // A 28 × 34 pt target: the circle is small, the area that answers a tap is not.
                                    MatrixCell(status: store.status(of: t, in: m), size: 18)
                                        .frame(width: 28, height: 34)
                                        .contentShape(Rectangle())
                                        .onTapGesture { ui.tapPayment(t, month: m, store: store); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                                        .onLongPressGesture { partial = PartialTarget(tenant: t, month: m) }
                                } else {
                                    Circle().fill(Color.secondary.opacity(0.08)).frame(width: 7, height: 7).frame(width: 28, height: 34)
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
                key(.paid, "coll.status.paid")
                key(.partial, "coll.status.partial")
                key(.overdue, "coll.status.overdue")
                key(.upcoming, "coll.status.upcoming")
            }
            .font(.caption2)
            Text("coll.hint").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }

    private func key(_ status: CollectionStatus, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 4) { MatrixCell(status: status).scaleEffect(0.6).frame(width: 14, height: 14); Text(title).foregroundStyle(.secondary) }
    }
}

private struct CollectionRow: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui
    let tenant: Tenant
    let month: MonthKey
    let onPartial: () -> Void
    let onReceipt: () -> Void

    var body: some View {
        let status = store.status(of: tenant, in: month)
        let paid = store.payment(of: tenant.id, in: month)
        HStack(spacing: 12) {
            Button {
                ui.tapPayment(tenant, month: month, store: store)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                MatrixCell(status: status).scaleEffect(1.5).frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(tenant.name).font(.subheadline.weight(.semibold))
                Text(store.unit(tenant.unitID)?.name ?? "").font(.caption).foregroundStyle(.secondary)
                if tenant.monthlyExpenses > 0 {
                    Text("coll.rent_plus \(store.rentDue(of: tenant, in: month).money) \(store.suppliesDue(of: tenant, in: month).money)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text((paid?.amount ?? tenant.monthlyTotal(in: month)).moneyExact).font(.subheadline.weight(.semibold))
                switch status {
                case .paid: Text(paid?.paidOn.short ?? "").font(.caption2).foregroundStyle(Color.income)
                case .partial: Pill(text: "coll.status.partial", color: .expense)
                case .overdue: Pill(text: "coll.status.overdue", color: .alert)
                case .upcoming:
                    if store.due(of: tenant, in: month) <= 0.005 { Pill(text: "coll.no_amount", color: .expense) }
                    else { Pill(text: "coll.status.upcoming", color: .gray) }
                }
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button { onPartial() } label: { Label("coll.partial", systemImage: "square.and.pencil") }
            if paid != nil { Button { onReceipt() } label: { Label("receipt.open", systemImage: "doc.text") } }
            if paid != nil { Button(role: .destructive) { store.removePayment(tenant, month: month) } label: { Label("coll.unmark", systemImage: "arrow.uturn.backward") } }
        }
        .onLongPressGesture { onPartial() }
    }
}

struct MatrixCell: View {
    let status: CollectionStatus
    var size: CGFloat = 22
    var body: some View {
        ZStack {
            switch status {
            case .paid:
                Circle().fill(Color.income)
                Image(systemName: "checkmark").font(.system(size: size * 0.42, weight: .heavy)).foregroundStyle(.white)
            case .partial:
                Circle().fill(Color.expense.opacity(0.25))
                Circle().trim(from: 0, to: 0.5).stroke(Color.expense, lineWidth: size * 0.23).rotationEffect(.degrees(-90)).padding(size * 0.23)
            case .overdue:
                Circle().stroke(Color.alert, lineWidth: 2)
                Text("!").font(.system(size: size * 0.45, weight: .heavy)).foregroundStyle(Color.alert)
            case .upcoming:
                Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 1.5)
            }
        }
        .frame(width: size, height: size)
        .frame(width: size + 3, height: size + 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
    }

    private var label: LocalizedStringKey {
        switch status {
        case .paid: "coll.status.paid"
        case .partial: "coll.status.partial"
        case .overdue: "coll.status.overdue"
        case .upcoming: "coll.status.upcoming"
        }
    }
}

/// Register a custom amount and date (partial payments, late payments), split into
/// rent and utilities: only the rent counts for the manager fee and the fiscal report.
struct PartialPaymentSheet: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tenant: Tenant
    let month: MonthKey
    @State private var rent: Double
    @State private var supplies: Double
    @State private var paidOn: Date
    @State private var showReceipt = false

    init(tenant: Tenant, month: MonthKey) {
        self.tenant = tenant
        self.month = month
        let store = RentalStore.shared
        let existing = store.payment(of: tenant.id, in: month)
        let parts = existing.map { store.split($0) }
        _rent = State(initialValue: parts?.rent ?? store.rentDue(of: tenant, in: month))
        _supplies = State(initialValue: parts?.supplies ?? tenant.monthlyExpenses)
        _paidOn = State(initialValue: existing?.paidOn ?? Date())
    }

    private var amount: Double { rent + supplies }

    var body: some View {
        NavigationStack {
            Form {
                Section { LabeledContent("coll.tenant", value: tenant.name); LabeledContent("coll.month", value: month.title()) }
                Section {
                    MoneyField("tenant.rent", value: $rent)
                    MoneyField("tenant.expenses", value: $supplies)
                    LabeledContent("coll.amount") { Text(amount.moneyExact).fontWeight(.semibold) }
                    DatePicker("coll.paid_on", selection: $paidOn, displayedComponents: .date)
                } footer: { Text("coll.expected \(store.due(of: tenant, in: month).moneyExact)") }
                if store.payment(of: tenant.id, in: month) != nil {
                    Section { Button { showReceipt = true } label: { Label("receipt.open", systemImage: "doc.text") } }
                    Section { Button("coll.unmark", role: .destructive) { store.removePayment(tenant, month: month); dismiss() } }
                }
            }
            .navigationTitle("coll.partial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { store.setPayment(tenant, month: month, rent: rent, supplies: supplies, paidOn: paidOn); dismiss() }.disabled(amount <= 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showReceipt) { ReceiptSheet(tenant: tenant, month: month) }
    }
}

// MARK: - Payment calendars

/// The last 12 months of one tenancy as a strip of circles, oldest on the leading side. It is an
/// overview only: at this size the circles cannot be tapped reliably, so months are ticked in the
/// Collections tab or in the tenant's own calendar.
struct PaymentStripRow: View {
    @Environment(RentalStore.self) private var store
    let tenant: Tenant
    let title: String
    var subtitle: String?

    var body: some View {
        let months = (0..<12).reversed().map { MonthKey.current.adding(-$0) }
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.weight(.semibold)).lineLimit(1)
                if let subtitle { Text(subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
            }
            Spacer(minLength: 4)
            HStack(spacing: 1) {
                ForEach(months) { m in
                    if tenant.isActive(in: m) {
                        MatrixCell(status: store.status(of: tenant, in: m), size: 11)
                    } else {
                        Circle().fill(Color.secondary.opacity(0.08)).frame(width: 5, height: 5).frame(width: 14, height: 14)
                    }
                }
            }
        }
    }
}

/// Every month of a tenancy, one row per year: the payment history at a glance.
struct PaymentCalendar: View {
    @Environment(RentalStore.self) private var store
    @Environment(AppUI.self) private var ui
    let tenant: Tenant
    @State private var partial: CollectionsView.PartialTarget?

    var body: some View {
        let months = store.tenancyMonths(tenant)
        let years = Array(Set(months.map(\.year))).sorted(by: >)
        let statuses = months.map { store.status(of: tenant, in: $0) }
        let paid = statuses.filter { $0 == .paid }.count
        let late = statuses.filter { $0 == .overdue || $0 == .partial }.count
        let owed = months.reduce(0.0) { acc, m in
            let st = store.status(of: tenant, in: m)
            guard st == .overdue || st == .partial else { return acc }
            return acc + max(0, store.due(of: tenant, in: m) - (store.payment(of: tenant.id, in: m)?.amount ?? 0))
        }
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Pill(text: "tenant.history.paid \(paid)", color: .income)
                if late > 0 { Pill(text: "tenant.history.late \(late)", color: .alert) }
                Spacer()
                if owed > 0.5 { Text(owed.money).font(.subheadline.weight(.semibold)).foregroundStyle(Color.alert) }
            }
            // Twelve columns share the width, each at least 36 pt tall: a tap lands on the month it meant.
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    Text("").frame(width: 34)
                    ForEach(1...12, id: \.self) { m in
                        Text(MonthKey(year: 2000, month: m).monthName(narrow: true)).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    }
                }
                ForEach(years, id: \.self) { y in
                    HStack(spacing: 0) {
                        Text(String(y)).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).frame(width: 34, alignment: .leading)
                        ForEach(MonthKey.months(of: y)) { m in
                            if months.contains(m) {
                                Button { ui.tapPayment(tenant, month: m, store: store); UIImpactFeedbackGenerator(style: .light).impactOccurred() } label: {
                                    MatrixCell(status: store.status(of: tenant, in: m), size: 16)
                                        .frame(maxWidth: .infinity, minHeight: 36)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .simultaneousGesture(LongPressGesture().onEnded { _ in partial = .init(tenant: tenant, month: m) })
                            } else {
                                Circle().fill(Color.secondary.opacity(0.08)).frame(width: 6, height: 6).frame(maxWidth: .infinity, minHeight: 36)
                            }
                        }
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(.vertical, 4)
        .sheet(item: $partial) { PartialPaymentSheet(tenant: $0.tenant, month: $0.month) }
    }
}
