//
//  RentUpdateSheet.swift
//  Renting
//
//  The annual rent update: pick the index of the contract, see the reference values and
//  the ceilings that apply, and get the new rent, the month it becomes due and the
//  notice letter. Nothing is applied silently: the percentage is always typed or
//  confirmed by the landlord, who is told when it exceeds the ceiling shown.
//

import SwiftUI

struct RentUpdateSheet: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Landlord.nameKey) private var landlordName = ""
    @AppStorage(Landlord.taxIDKey) private var landlordTaxID = ""
    let review: RentReview
    @State private var index: RentIndex
    @State private var percent: Double
    @State private var notifiedOn = Date()
    @State private var url: URL?
    @State private var version = 0

    private var tenant: Tenant { store.tenant(review.tenant.id) ?? review.tenant }

    init(review: RentReview) {
        self.review = review
        let store = RentalStore.shared
        let t = review.tenant
        let automatic = store.updateIndex(for: t)
        _index = State(initialValue: automatic == .none ? .manual : automatic)
        let cap = RentRules.cap(contractStart: t.entryDate, anniversary: review.anniversary, seasonal: store.isSeasonal(t))
        // Old reference values are not suggested: a notice with a stale index can be wrong.
        _percent = State(initialValue: RentRules.isStale ? 0 : (cap?.percent ?? 0))
    }

    private var cap: RentRules.Cap? {
        RentRules.cap(contractStart: tenant.entryDate, anniversary: review.anniversary, seasonal: store.isSeasonal(tenant))
    }
    private var newRent: Double { (tenant.monthlyRent * (1 + percent / 100) * 100).rounded() / 100 }
    private var effective: MonthKey { store.effectiveMonth(anniversary: review.anniversary, notifiedOn: notifiedOn) }
    private var overCap: Bool { cap.map { percent > $0.percent + 0.0001 } ?? false }
    private var draft: RentChange {
        RentChange(effective: effective, previous: tenant.monthlyRent, new: newRent, index: index,
                   percent: percent, cycle: review.cycle, notifiedOn: notifiedOn)
    }
    private var canApply: Bool { percent > 0 && abs(newRent - tenant.monthlyRent) > 0.004 }
    private var isPending: Bool { store.pendingReview(for: tenant)?.cycle == review.cycle }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("coll.tenant", value: tenant.name)
                    LabeledContent("upd.anniversary") { Text("\(review.anniversary.short) · \(L("upd.year_n", review.cycle))") }
                    LabeledContent("upd.current", value: tenant.monthlyRent.moneyExact)
                }

                Section {
                    Picker("upd.index", selection: $index) {
                        ForEach([RentIndex.irav, .ipc, .fixed, .manual]) { Text($0.label).tag($0) }
                    }
                    MoneyField("upd.percent", value: $percent, suffix: "%")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("upd.irav_ref \(RentRules.iravPercent.percentText) \(RentRules.iravMonth.title())").font(.footnote)
                        HStack(spacing: 16) {
                            Button("upd.use \(RentRules.iravPercent.percentText)") { percent = RentRules.iravPercent }
                            Link("upd.ine", destination: RentRules.iravURL)
                        }
                        .font(.footnote.weight(.semibold))
                        .buttonStyle(.borderless)
                    }
                    if RentRules.isStale {
                        Label("upd.stale \(RentRules.daysOld)", systemImage: "clock.badge.exclamationmark").font(.footnote).foregroundStyle(Color.expense)
                    }
                    if let cap {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("upd.cap \(cap.percent.percentText)").font(.footnote.weight(.semibold))
                            if cap.irav { Text("upd.cap.irav").font(.caption).foregroundStyle(.secondary) }
                            if cap.decree { Text("upd.cap.decree").font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    if overCap {
                        Label("upd.over_cap", systemImage: "exclamationmark.triangle.fill").font(.footnote).foregroundStyle(Color.alert)
                    }
                } header: { Text("upd.index") } footer: { Text("upd.rules_asof \(RentRules.asOf.short)") }

                Section {
                    DatePicker("upd.notified_on", selection: $notifiedOn, displayedComponents: .date)
                    LabeledContent("upd.new") { Text(newRent.moneyExact).fontWeight(.bold).foregroundStyle(Color.brand) }
                    LabeledContent("upd.diff") { Text((newRent - tenant.monthlyRent).signedMoney).foregroundStyle(.secondary) }
                    LabeledContent("upd.effective", value: effective.title())
                } footer: { Text("upd.effective.footer") }

                Section {
                    TextField("receipt.landlord_name", text: $landlordName).textContentType(.name)
                    TextField("receipt.landlord_tax_id", text: $landlordTaxID).textInputAutocapitalization(.characters).autocorrectionDisabled()
                } header: { Text("receipt.landlord") } footer: { Text("receipt.landlord.footer") }

                if canApply, let url {
                    Section {
                        PDFPreview(url: url, version: version)
                            .aspectRatio(595.0 / 842.0, contentMode: .fit)
                            .listRowInsets(EdgeInsets())
                        ShareLink(item: url) { Label("upd.letter.share", systemImage: "square.and.arrow.up") }
                    } header: { Text("upd.letter") } footer: { Text("upd.letter.footer") }
                }

                if isPending {
                    Section {
                        Button("upd.keep") { keep() }
                    } footer: { Text("upd.keep.footer") }
                }
            }
            .navigationTitle("upd.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("upd.apply") { store.applyRentChange(draft, to: tenant); dismiss() }.disabled(!canApply)
                }
            }
            .task { regenerate() }
            .onChange(of: percent) { _, _ in regenerate() }
            .onChange(of: index) { _, _ in regenerate() }
            .onChange(of: notifiedOn) { _, _ in regenerate() }
            .onChange(of: landlordName) { _, _ in regenerate() }
            .onChange(of: landlordTaxID) { _, _ in regenerate() }
        }
    }

    private func regenerate() {
        guard canApply else { url = nil; return }
        url = RentLetterService.make(tenant: tenant, change: draft, store: store)
        version += 1
    }

    /// The landlord decides not to raise the rent this year: recorded so the reminder stops.
    private func keep() {
        let change = RentChange(effective: MonthKey(review.anniversary), previous: tenant.monthlyRent, new: tenant.monthlyRent,
                                index: index, percent: 0, cycle: review.cycle, notifiedOn: nil)
        store.applyRentChange(change, to: tenant)
        dismiss()
    }
}

/// A saved update's notice letter, to look at again or send.
struct RentLetterSheet: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tenant: Tenant
    let change: RentChange
    @State private var url: URL?

    var body: some View {
        NavigationStack {
            Group {
                if let url { PDFPreview(url: url, version: 0).padding(.horizontal) } else { ProgressView() }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("upd.letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.done") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if let url { ShareLink(item: url) { Label("upd.letter.share", systemImage: "square.and.arrow.up") } }
                }
            }
            .task { url = RentLetterService.make(tenant: tenant, change: change, store: store) }
        }
    }
}
