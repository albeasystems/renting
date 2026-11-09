//
//  WidgetSnapshot.swift
//  Renting
//
//  What the "Collections" widget shows, as the app leaves it for the widget. The widget is a
//  separate process with its own container and none of the app's logic, so the app does the
//  work (totals, who has not paid, text in the in-app language and currency) and writes the
//  result to a small file in the App Group container; the widget only draws it.
//
//  Nothing in the snapshot depends on the calendar of the device: the moments that matter
//  (when an unpaid rent starts to count as overdue, when the month ends) are stored as dates,
//  so the widget can change what it shows on its own while the app is closed.
//

import Foundation

struct WidgetSnapshot: Codable, Equatable {
    /// A tenant who still owes something this month.
    struct Row: Codable, Equatable {
        var name: String
        /// What is still owed, formatted.
        var amount: String
        /// Paid something, but not everything: late whatever the day.
        var partial: Bool
        /// From this moment an unpaid month counts as overdue.
        var lateFrom: Date

        func isLate(at date: Date) -> Bool { partial || date >= lateFrom }
    }

    static let currentVersion = 1

    var version = WidgetSnapshot.currentVersion
    /// "October": the month the figures are about.
    var monthName: String
    var monthStart: Date
    var nextMonthStart: Date
    /// No tenants this month (or no data at all): there is nothing to show.
    var isEmpty: Bool
    /// Collected ÷ expected, between 0 and 1.
    var fraction: Double
    var percentText: String
    var collectedText: String
    /// "of 6,590 €".
    var ofExpectedText: String
    /// "1,090 € still to collect"; empty when everything is in.
    var pendingText: String
    var pendingCount: Int
    /// The tenants who owe the most, at most three, the late ones first.
    var rows: [Row]
    /// "+2 more" when there are more than the rows shown; empty otherwise.
    var moreText: String
    var allCollectedText: String
    /// Shown instead of the figures once the month in the snapshot is over.
    var staleText: String
    var emptyText: String
    var isRightToLeft: Bool
    var updated: Date

    /// The month the snapshot describes is not the one it is now.
    func isStale(at date: Date) -> Bool { date < monthStart || date >= nextMonthStart }

    func hasLateRows(at date: Date) -> Bool { rows.contains { $0.isLate(at: date) } }
}

/// Where the snapshot lives: a file in the container the app and the widget share.
enum WidgetStorage {
    static let group = "group.com.albeasystems.renting"
    /// Identifies the widget to WidgetKit (to reload it).
    static let kind = "CollectionsWidget"

    static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent("collections-widget.json")
    }

    /// The shared container exists (the App Group is in the entitlements of the running binary).
    static var isAvailable: Bool { fileURL != nil }

    static func read() -> WidgetSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
              snapshot.version == WidgetSnapshot.currentVersion else { return nil }
        return snapshot
    }

    @discardableResult
    static func write(_ snapshot: WidgetSnapshot) -> Bool {
        guard let url = fileURL, let data = try? JSONEncoder().encode(snapshot) else { return false }
        return (try? data.write(to: url, options: .atomic)) != nil
    }
}
