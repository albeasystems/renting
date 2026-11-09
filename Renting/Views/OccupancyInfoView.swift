//
//  OccupancyInfoView.swift
//  Renting
//
//  The (i) of the Occupancy card on the Summary tab: for every year, how much of the time the
//  homes were let, all together and one by one (with the rooms of a shared home listed under it).
//

import SwiftUI
import Charts

struct OccupancyInfoView: View {
    @Environment(RentalStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let all = store.occupancyHistory()
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if all.isEmpty {
                        Text("occ.info.none").font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 40)
                    } else {
                        overview(all)
                        ForEach(store.data.properties) { property in
                            let history = store.occupancyHistory(property: property.id)
                            if !history.isEmpty { propertyCard(property, history) }
                        }
                        Text("occ.info.footer").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("occ.info.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() } } }
        }
    }

    // MARK: Every home together

    private func overview(_ history: [OccupancyYear]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("occ.info.all").font(.headline)
                Spacer()
                if let last = history.last { Text("\(last.percent) %").font(.headline).foregroundStyle(color(last.share)) }
            }
            Chart(history) { row in
                BarMark(x: .value("y", String(row.year)), y: .value("p", row.share))
                    .foregroundStyle(color(row.share))
                    .annotation(position: .top) { Text("\(row.percent)").font(.caption2).foregroundStyle(.secondary) }
            }
            .chartYScale(domain: 0...1.15)
            .chartYAxis(.hidden)
            .frame(height: 150)
        }
        .card()
    }

    // MARK: One home

    private func propertyCard(_ property: Property, _ history: [OccupancyYear]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(property.name).font(.headline)
                Spacer()
                if let last = history.last { Text("\(last.percent) %").font(.headline).foregroundStyle(color(last.share)) }
            }
            ForEach(history.reversed()) { row in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(label(row)).font(.subheadline)
                        Spacer()
                        if row.empty > 0 { Text(L("occ.info.empty_days", row.empty)).font(.caption).foregroundStyle(.secondary) }
                        Text("\(row.percent) %").font(.subheadline.weight(.semibold)).foregroundStyle(color(row.share))
                    }
                    GeometryReader { geo in
                        Capsule().fill(Color.secondary.opacity(0.15)).overlay(alignment: .leading) {
                            Capsule().fill(color(row.share)).frame(width: max(row.share > 0 ? 6 : 0, geo.size.width * row.share))
                        }
                    }
                    .frame(height: 6)
                }
            }
            if property.kind == .rooms { rooms(of: property) }
        }
        .card()
    }

    /// The rooms of a shared home, each with its percentage year by year.
    private func rooms(of property: Property) -> some View {
        let rows: [(unit: Unit, history: [OccupancyYear])] = store.units(of: property.id)
            .map { ($0, store.occupancyHistory(units: [$0])) }
            .filter { !$0.history.isEmpty }
        return DisclosureGroup {
            ForEach(rows, id: \.unit.id) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.unit.name).font(.subheadline.weight(.semibold))
                    Text(row.history.map { "\($0.year) · \($0.percent) %" }.joined(separator: "   "))
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 3)
            }
        } label: {
            Text("occ.info.rooms").font(.subheadline.weight(.semibold))
        }
    }

    // MARK: Helpers

    /// "2025", or "2026 (to date)" for the year in progress.
    private func label(_ row: OccupancyYear) -> String {
        row.year == MonthKey.current.year ? L("occ.info.to_date", String(row.year)) : String(row.year)
    }

    private func color(_ share: Double) -> Color {
        share >= 0.9 ? .income : (share >= 0.7 ? .gold : .alert)
    }
}
