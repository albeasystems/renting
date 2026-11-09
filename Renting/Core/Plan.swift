//
//  Plan.swift
//  Renting
//
//  What each plan includes. There are two: the free plan and the "Renting Cloud" subscription.
//  `StoreManager` is the only place that decides who is subscribed; the rest of the app asks
//  `StoreManager.shared.hasCloud` (or reads the mirrored `isProUnlocked` flag in a view).
//
//  FREE
//    • Up to `freeHomeLimit` homes of any kind (whole home, by rooms, seasonal).
//    • Tenants with their rent and utilities, dates, deposit and extra-guarantee amounts.
//    • Collections, expenses, Summary, occupancy history, widget, backup file, on-screen alerts.
//    • Fiscal tab: rent collected, deductible expenses and the net before reductions.
//    • Ads. A rewarded video removes them for an hour and unlocks the fiscal report for that hour.
//
//  SUBSCRIPTION
//    • Unlimited homes.
//    • Homes: manager or agency fee (+ VAT), construction and cadastral values, own-home flag.
//    • Tenants: contract type and rent insurance, yearly rent update (IRAV/CPI) with its letter,
//      deposit filing control, income-tax reduction per contract, rent receipts.
//    • Fiscal: depreciation, reductions, income imputed to empty days, choosing which expenses
//      are deductible, PDF/CSV report.
//    • Smart alerts with notifications, no ads, iCloud sync and backup.
//
//  Nothing the landlord already typed is ever hidden or deleted when a subscription ends: the
//  advanced fields stay in the data (and in the figures) but can only be edited while subscribed.
//

import Foundation

@MainActor
enum Plan {
    /// Homes the free plan can have.
    static let freeHomeLimit = 3

    /// Whether one more home can be added: always when subscribed, otherwise below the free limit.
    static func canAddHome(count: Int, subscribed: Bool) -> Bool {
        subscribed || count < freeHomeLimit
    }

    static var isSubscriber: Bool { StoreManager.shared.hasCloud }
}

extension RentalStore {
    /// One more home fits in the current plan. Existing homes are never removed or hidden when
    /// the limit is passed (a lapsed subscription, a backup, the sample data): only adding stops.
    var canAddHome: Bool { Plan.canAddHome(count: data.properties.count, subscribed: StoreManager.shared.hasCloud) }
}
