//
//  WidgetBridge.swift
//  Renting
//
//  Keeps the "Collections" widget up to date: after every change to the data (and when the
//  app starts, goes to the background, or the language or currency change) it rebuilds the
//  snapshot the widget draws (see `WidgetSnapshot`) and asks WidgetKit to redraw it.
//

import Foundation
import WidgetKit

@MainActor
enum WidgetBridge {
    private static var pending: Task<Void, Never>?

    /// Rebuilds and publishes the snapshot after a short pause: edits come in bursts.
    static func refresh() {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            WidgetStorage.write(makeSnapshot(store: .shared, now: Date()))
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetStorage.kind)
        }
    }

    /// The month's collection as the widget shows it.
    static func makeSnapshot(store: RentalStore, now: Date) -> WidgetSnapshot {
        let month = MonthKey(now)
        let locale = AppLanguage.shared.locale
        let totals = store.totals(in: month)
        let tenants = store.tenants(in: month)
        // An unpaid month counts as overdue from the day after the due day (an alert-rule setting).
        let lateFrom = Calendar.current.date(byAdding: .day, value: RentalStore.dueDay, to: month.start) ?? month.start

        struct Owing { let name: String; let owed: Double; let partial: Bool; let late: Bool }
        var owing: [Owing] = []
        for t in tenants {
            let status = store.status(of: t, in: month, now: now)
            guard status != .paid else { continue }
            let paid = store.payment(of: t.id, in: month)?.amount ?? 0
            owing.append(Owing(name: t.name, owed: max(0, store.due(of: t, in: month) - paid), partial: status == .partial, late: status != .upcoming))
        }
        // The late ones first, then whoever owes the most.
        owing.sort { ($0.late ? 0 : 1, -$0.owed) < ($1.late ? 0 : 1, -$1.owed) }

        let shown = 3
        let fraction = totals.expected > 0 ? min(1, max(0, totals.collected / totals.expected)) : 0
        return WidgetSnapshot(
            monthName: month.start.formatted(.dateTime.locale(locale).month(.wide)),
            monthStart: month.start,
            nextMonthStart: month.adding(1).start,
            isEmpty: tenants.isEmpty,
            fraction: fraction,
            percentText: fraction.formatted(.percent.precision(.fractionLength(0)).locale(locale)),
            collectedText: totals.collected.money,
            ofExpectedText: L("widget.of", totals.expected.money),
            pendingText: totals.pending > 0.5 ? L("coll.pending %@", totals.pending.money) : "",
            pendingCount: owing.count,
            rows: owing.prefix(shown).map { WidgetSnapshot.Row(name: $0.name, amount: $0.owed.money, partial: $0.partial, lateFrom: lateFrom) },
            moreText: owing.count > shown ? L("widget.more", owing.count - shown) : "",
            allCollectedText: L("props.all_paid"),
            staleText: L("widget.stale"),
            emptyText: L("widget.empty"),
            isRightToLeft: AppLanguage.shared.isRightToLeft,
            updated: now)
    }
}
