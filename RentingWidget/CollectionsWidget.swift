//
//  CollectionsWidget.swift
//  RentingWidget
//
//  "Collections of the month": how much rent has come in, and who still owes. Small and medium
//  on the Home Screen; circular, rectangular and inline on the Lock Screen. It draws the
//  snapshot the app leaves in the shared container (`WidgetSnapshot`) and, on its own, flips a
//  month that is still unpaid from "upcoming" to "late" on the due day and notices when the
//  month is over. Tapping it opens the Collections tab.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct CollectionsEntry: TimelineEntry {
    let date: Date
    /// `nil` until the app has run once and written one.
    let snapshot: WidgetSnapshot?
}

struct CollectionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> CollectionsEntry {
        CollectionsEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (CollectionsEntry) -> Void) {
        completion(CollectionsEntry(date: .now, snapshot: WidgetStorage.read() ?? (context.isPreview ? .sample : nil)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CollectionsEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetStorage.read()
        var entries = [CollectionsEntry(date: now, snapshot: snapshot)]
        if let snapshot {
            // The moment unpaid rents start to count as overdue, and the turn of the month.
            let changes = Set(snapshot.rows.map(\.lateFrom) + [snapshot.nextMonthStart]).filter { $0 > now }.sorted()
            entries += changes.map { CollectionsEntry(date: $0, snapshot: snapshot) }
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(6 * 3600))))
    }
}

// MARK: - Widget

struct CollectionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetStorage.kind, provider: CollectionsProvider()) { entry in
            CollectionsView(entry: entry)
        }
        .configurationDisplayName("widget.name")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Views

struct CollectionsView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CollectionsEntry

    var body: some View {
        content
            .environment(\.layoutDirection, (entry.snapshot?.isRightToLeft ?? false) ? .rightToLeft : .leftToRight)
            .widgetURL(URL(string: "renting://collections"))
            .containerBackground(for: .widget) {
                switch family {
                case .accessoryCircular, .accessoryRectangular, .accessoryInline: Color.clear
                default: Color(uiColor: .systemBackground)
                }
            }
    }

    @ViewBuilder private var content: some View {
        if let s = entry.snapshot {
            let stale = s.isStale(at: entry.date)
            switch family {
            case .systemMedium: MediumView(snapshot: s, date: entry.date, stale: stale)
            case .accessoryCircular: CircularView(snapshot: s, stale: stale)
            case .accessoryRectangular: RectangularView(snapshot: s, stale: stale)
            case .accessoryInline: InlineView(snapshot: s, stale: stale)
            default: SmallView(snapshot: s, date: entry.date, stale: stale)
            }
        } else {
            NotStartedView()
        }
    }
}

/// Before the app has written anything: just the name, in any language.
private struct NotStartedView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "house.fill").font(.title2).foregroundStyle(Color.brand)
            Text(verbatim: "Renting").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private func hint(_ s: WidgetSnapshot, stale: Bool) -> String { stale ? s.staleText : s.emptyText }

/// Month name and a small house.
private struct Header: View {
    let snapshot: WidgetSnapshot
    var body: some View {
        HStack {
            Text(snapshot.monthName).font(.caption2.weight(.bold)).textCase(.uppercase).foregroundStyle(Color.brand).lineLimit(1)
            Spacer(minLength: 4)
            Image(systemName: "house.fill").font(.caption2).foregroundStyle(Color.brand)
        }
    }
}

/// "All collected" or what is still to collect, red once something is late.
private struct Footer: View {
    let snapshot: WidgetSnapshot
    let date: Date
    var body: some View {
        if snapshot.pendingCount == 0 {
            Label { Text(snapshot.allCollectedText) } icon: { Image(systemName: "checkmark.circle.fill") }
                .font(.caption.weight(.semibold)).foregroundStyle(Color.income).lineLimit(1).minimumScaleFactor(0.7)
        } else {
            Text(snapshot.pendingText).font(.caption.weight(.semibold))
                .foregroundStyle(snapshot.hasLateRows(at: date) ? Color.alert : Color.gold)
                .lineLimit(1).minimumScaleFactor(0.7).privacySensitive()
        }
    }
}

/// The big figure, the month's total and the progress bar.
private struct Figures: View {
    let snapshot: WidgetSnapshot
    let date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(snapshot.collectedText)
                .font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Color.income)
                .lineLimit(1).minimumScaleFactor(0.6).privacySensitive()
            Text(snapshot.ofExpectedText).font(.caption).foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.7).privacySensitive()
            ProgressView(value: snapshot.fraction).tint(Color.income).padding(.vertical, 2)
            Footer(snapshot: snapshot, date: date)
        }
    }
}

private struct SmallView: View {
    let snapshot: WidgetSnapshot
    let date: Date
    let stale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Header(snapshot: snapshot)
            Spacer(minLength: 0)
            if snapshot.isEmpty || stale {
                Text(hint(snapshot, stale: stale)).font(.caption).foregroundStyle(.secondary).lineLimit(4)
                Spacer(minLength: 0)
            } else {
                Figures(snapshot: snapshot, date: date)
            }
        }
    }
}

private struct MediumView: View {
    let snapshot: WidgetSnapshot
    let date: Date
    let stale: Bool

    var body: some View {
        if snapshot.isEmpty || stale {
            VStack(alignment: .leading, spacing: 6) {
                Header(snapshot: snapshot)
                Spacer(minLength: 0)
                Text(hint(snapshot, stale: stale)).font(.subheadline).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        } else {
            // The figures take only what they need: the names on the right are the long text.
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Header(snapshot: snapshot)
                    Spacer(minLength: 0)
                    Figures(snapshot: snapshot, date: date)
                }
                .frame(width: 118)
                Divider()
                owing
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private var owing: some View {
        if snapshot.rows.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundStyle(Color.income)
                Text(snapshot.allCollectedText).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(snapshot.rows.enumerated()), id: \.offset) { _, row in
                    let color = row.partial ? Color.expense : (row.isLate(at: date) ? Color.alert : Color.secondary)
                    HStack(spacing: 6) {
                        Circle().fill(color).frame(width: 7, height: 7)
                        Text(row.name).font(.caption).lineLimit(1)
                        Spacer(minLength: 4)
                        Text(row.amount).font(.caption.weight(.semibold)).foregroundStyle(color).lineLimit(1)
                    }
                    .privacySensitive()
                }
                if !snapshot.moreText.isEmpty {
                    Text(snapshot.moreText).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
    }
}

// MARK: Lock Screen

private struct CircularView: View {
    let snapshot: WidgetSnapshot
    let stale: Bool
    var body: some View {
        if snapshot.isEmpty || stale {
            ZStack { AccessoryWidgetBackground(); Image(systemName: "house.fill") }
        } else {
            Gauge(value: snapshot.fraction) { EmptyView() } currentValueLabel: {
                Text(snapshot.percentText).font(.caption.weight(.semibold)).minimumScaleFactor(0.6).privacySensitive()
            }
            .gaugeStyle(.accessoryCircularCapacity)
        }
    }
}

private struct RectangularView: View {
    let snapshot: WidgetSnapshot
    let stale: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(snapshot.monthName).font(.headline).widgetAccentable().lineLimit(1)
            if snapshot.isEmpty || stale {
                Text(hint(snapshot, stale: stale)).font(.caption).lineLimit(2)
            } else {
                HStack {
                    Text(snapshot.collectedText).font(.caption.weight(.semibold)).privacySensitive()
                    Spacer(minLength: 4)
                    Text(snapshot.ofExpectedText).font(.caption).privacySensitive()
                }
                .lineLimit(1).minimumScaleFactor(0.7)
                Gauge(value: snapshot.fraction) { EmptyView() }.gaugeStyle(.accessoryLinearCapacity)
            }
        }
    }
}

private struct InlineView: View {
    let snapshot: WidgetSnapshot
    let stale: Bool
    var body: some View {
        if snapshot.isEmpty || stale {
            Text(snapshot.monthName)
        } else {
            Label { Text("\(snapshot.collectedText) · \(snapshot.percentText)").privacySensitive() } icon: { Image(systemName: "house.fill") }
        }
    }
}

// MARK: - Sample (gallery and previews)

extension WidgetSnapshot {
    /// Shown in the widget gallery before the app has written real figures.
    static var sample: WidgetSnapshot {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
        let next = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? start
        let late = Calendar.current.date(byAdding: .day, value: 5, to: start) ?? start
        return WidgetSnapshot(
            monthName: start.formatted(.dateTime.month(.wide)), monthStart: start, nextMonthStart: next, isEmpty: false,
            fraction: 0.83, percentText: "83%", collectedText: "€5,500", ofExpectedText: "of €6,590", pendingText: "€1,090 still to collect",
            pendingCount: 3,
            rows: [.init(name: "Ana Costa", amount: "€370", partial: false, lateFrom: late),
                   .init(name: "Jorge Silva", amount: "€390", partial: false, lateFrom: late),
                   .init(name: "Carlos Peña", amount: "€330", partial: true, lateFrom: late)],
            moreText: "", allCollectedText: "All paid", staleText: "Open Renting to update", emptyText: "Add homes and tenants in Renting",
            isRightToLeft: false, updated: .now)
    }
}

#if DEBUG
#Preview("Small", as: .systemSmall) { CollectionsWidget() } timeline: { CollectionsEntry(date: .now, snapshot: .sample) }
#Preview("Medium", as: .systemMedium) { CollectionsWidget() } timeline: { CollectionsEntry(date: .now, snapshot: .sample) }
#endif
