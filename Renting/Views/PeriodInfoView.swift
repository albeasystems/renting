//
//  PeriodInfoView.swift
//  Renting
//
//  The quick view behind the (i) of the income-vs-expenses chart: what came in and what went
//  out in a month (or a quarter, or a year), line by line, with what is still owed or unpaid.
//  The period starts as the one selected on the Summary tab and can be changed here.
//

import SwiftUI

struct PeriodInfoView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var period: ReportPeriod
    let property: UUID?

    var body: some View {
        let t = store.totals(period, property: property)
        let income = store.incomeRows(period, property: property)
        let expenses = period.kind == .month
            ? store.chargeRows(in: period.anchor, property: property)
            : store.expenseRows(period, property: property)
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    selector
                    summary(t)
                    section("quick.income", total: t.collected, color: .income, empty: "quick.income.empty", rows: income, expensesStyle: false)
                    section("quick.expenses", total: t.expenses, color: .expense, empty: "quick.expenses.empty", rows: expenses, expensesStyle: true)
                    Text("quick.footer").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 8)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("quick.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
        }
    }

    // MARK: Period

    private var selector: some View {
        VStack(spacing: 10) {
            Picker("", selection: Binding(get: { period.kind }, set: { period = period.with(kind: $0) })) {
                Text("period.month").tag(PeriodKind.month)
                Text("period.quarter").tag(PeriodKind.quarter)
                Text("period.year").tag(PeriodKind.year)
            }.pickerStyle(.segmented)
            HStack {
                Button { period = period.moved(by: -1) } label: { Image(systemName: "chevron.backward") }
                Spacer()
                Text(period.title).font(.headline)
                Spacer()
                Button { period = period.moved(by: 1) } label: { Image(systemName: "chevron.forward") }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: Summary

    private func summary(_ t: Totals) -> some View {
        let top = max(t.collected, t.expenses, 1)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                KPI(title: "dash.collected", value: t.collected.money, color: .income)
                KPI(title: "dash.expenses", value: t.expenses.money, color: .expense)
                KPI(title: "dash.net_short", value: t.net.signedMoney, color: t.net >= 0 ? .income : .alert)
            }
            bar(t.collected, of: top, color: .income)
            bar(t.expenses, of: top, color: .expense)
            HStack(spacing: 8) {
                if t.rent > 0 { Pill(text: "kpi.eq.rent \(t.rent.money)", color: .income) }
                if t.supplies > 0 { Pill(text: "kpi.eq.supplies \(t.supplies.money)", color: .teal) }
                if t.pending > 0.5 { Pill(text: "quick.owed \(t.pending.money)", color: .alert) }
            }
        }
        .card()
    }

    private func bar(_ value: Double, of top: Double, color: Color) -> some View {
        GeometryReader { geo in
            Capsule().fill(color.opacity(0.85)).frame(width: max(value > 0 ? 6 : 0, geo.size.width * value / top), height: 8)
        }
        .frame(height: 8)
    }

    // MARK: Lists

    private func section(_ title: LocalizedStringKey, total: Double, color: Color, empty: LocalizedStringKey, rows: [QuickRow], expensesStyle: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(total.money).font(.headline).foregroundStyle(color)
            }
            .padding(.bottom, 10)
            if rows.isEmpty { Text(empty).font(.footnote).foregroundStyle(.secondary) }
            ForEach(rows) { row in
                HStack(spacing: 12) {
                    leading(row, color: color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(row.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                        if !row.subtitle.isEmpty { Text(row.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(row.amount.moneyExact).font(.subheadline.weight(.semibold))
                        if row.outstanding > 0.5 {
                            Text(expensesStyle ? "quick.unpaid \(row.outstanding.money)" : "quick.owes \(row.outstanding.money)")
                                .font(.caption2.weight(.semibold)).foregroundStyle(Color.alert)
                        }
                    }
                }
                .padding(.vertical, 7)
                if row.id != rows.last?.id { Divider() }
            }
        }
        .card()
    }

    @ViewBuilder private func leading(_ row: QuickRow, color: Color) -> some View {
        if let cat = row.category {
            Image(systemName: cat.icon).font(.footnote).foregroundStyle(.white).frame(width: 28, height: 28)
                .background(cat.color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        } else {
            Image(systemName: row.outstanding > 0.5 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.title3).foregroundStyle(row.outstanding > 0.5 ? Color.alert : color).frame(width: 28)
        }
    }
}
