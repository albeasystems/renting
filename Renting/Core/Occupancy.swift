//
//  Occupancy.swift
//  Renting
//
//  The occupancy history behind the (i) of the Summary tab: for each year, which share of the
//  days a room could have been let it actually had a tenant. A room counts from the day it first
//  had a tenant (before that it was not under management) and the current year counts up to
//  today, so neither the first year nor the running one look emptier than they were.
//

import Foundation

/// How much of a year a room, a home or every home was let.
struct OccupancyYear: Identifiable, Equatable {
    let year: Int
    /// Days with a tenant, and days that could have been let.
    var rented: Int
    var available: Int

    var id: Int { year }
    var empty: Int { available - rented }
    var share: Double { available > 0 ? Double(rented) / Double(available) : 0 }
    var percent: Int { Int((share * 100).rounded()) }
}

extension RentalStore {

    /// Days of `year` the room had a tenant and days it could have had one (see the file header).
    func occupancyDays(unit: UUID, year: Int, now: Date = Date()) -> (rented: Int, available: Int) {
        observeData()
        let cal = Calendar.current
        let tenants = self.tenants(of: unit)
        guard let start = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
              let first = tenants.map({ cal.startOfDay(for: $0.entryDate) }).min() else { return (0, 0) }
        let total = Self.days(in: year)
        func offset(_ date: Date) -> Int { cal.dateComponents([.day], from: start, to: cal.startOfDay(for: date)).day ?? 0 }
        let lo = max(0, offset(first))
        let hi = min(total - 1, offset(now))
        guard lo <= hi else { return (0, 0) }
        var days = Set<Int>()
        for t in tenants {
            let a = max(lo, offset(t.entryDate))
            let b = min(hi, t.exitDate.map(offset) ?? hi)
            if a <= b { days.formUnion(a...b) }
        }
        return (days.count, hi - lo + 1)
    }

    /// Year by year, oldest first, for some rooms together. Years without any day to measure are left out.
    func occupancyHistory(units: [Unit], now: Date = Date()) -> [OccupancyYear] {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: now)
        let firstYear = units.compactMap { tenants(of: $0.id).map(\.entryDate).min() }.map { cal.component(.year, from: $0) }.min()
        guard let firstYear, firstYear <= currentYear else { return [] }
        return (firstYear...currentYear).compactMap { year in
            var row = OccupancyYear(year: year, rented: 0, available: 0)
            for u in units {
                let d = occupancyDays(unit: u.id, year: year, now: now)
                row.rented += d.rented
                row.available += d.available
            }
            return row.available > 0 ? row : nil
        }
    }

    func occupancyHistory(property: UUID, now: Date = Date()) -> [OccupancyYear] {
        occupancyHistory(units: units(of: property), now: now)
    }

    /// Every home together, each room counting the same.
    func occupancyHistory(now: Date = Date()) -> [OccupancyYear] {
        occupancyHistory(units: data.units, now: now)
    }
}
