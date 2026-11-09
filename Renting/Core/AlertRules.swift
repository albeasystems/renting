//
//  AlertRules.swift
//  Renting
//
//  The rule engine behind the alerts. Every alert comes from one rule with its own
//  settings: shown or not, a threshold the landlord can tune (day of the month, days of
//  notice, percentage) and whether it also sends a local notification. The settings live
//  on the device (UserDefaults); the rules themselves are evaluated by `RentalStore.alerts`
//  and scheduled by `AlertsManager`.
//

import Foundation
import Observation
import SwiftUI

enum AlertSeverity: Int, Comparable {
    /// Needs an action now.
    case high
    /// Coming up.
    case normal
    /// Good to know.
    case info

    static func < (a: AlertSeverity, b: AlertSeverity) -> Bool { a.rawValue < b.rawValue }
}

enum AlertRuleKind: String, Codable, CaseIterable, Identifiable {
    case lateRent, expectedRent
    case upcomingExpense, unpaidExpense, utilityIncrease, suppliesGap
    case vacancy, contractEnding, rentUpdate, depositReturn, depositFiling

    var id: String { rawValue }
    var title: LocalizedStringKey { LocalizedStringKey("rule." + rawValue) }
    var name: String { L("rule." + rawValue) }
    var detail: LocalizedStringKey { LocalizedStringKey("rule." + rawValue + ".detail") }

    var icon: String {
        switch self {
        case .lateRent: "exclamationmark.circle.fill"
        case .expectedRent: "tray.and.arrow.down.fill"
        case .upcomingExpense: "calendar.badge.exclamationmark"
        case .unpaidExpense: "creditcard.trianglebadge.exclamationmark.fill"
        case .utilityIncrease: "bolt.badge.clock.fill"
        case .suppliesGap: "arrow.down.right.circle.fill"
        case .vacancy: "door.left.hand.open"
        case .contractEnding: "doc.text.fill"
        case .rentUpdate: "chart.line.uptrend.xyaxis"
        case .depositReturn: "lock.open.fill"
        case .depositFiling: "building.columns.fill"
        }
    }

    var color: Color {
        switch self {
        case .lateRent, .depositFiling, .unpaidExpense: .alert
        case .expectedRent, .rentUpdate: .brand
        case .upcomingExpense, .utilityIncrease, .suppliesGap: .expense
        case .vacancy, .depositReturn: .gold
        case .contractEnding: .indigo
        }
    }

    /// Where the alert takes the landlord when tapped.
    var destination: AppTab {
        switch self {
        case .lateRent, .expectedRent: .collections
        case .upcomingExpense, .unpaidExpense, .utilityIncrease, .suppliesGap: .expenses
        case .vacancy, .contractEnding, .rentUpdate, .depositReturn, .depositFiling: .properties
        }
    }

    enum Unit {
        case dayOfMonth, days, percent
        var label: String {
            switch self {
            case .dayOfMonth: L("rule.unit.day")
            case .days: L("rule.unit.days")
            case .percent: "%"
            }
        }
    }

    /// The threshold the landlord can tune: its meaning, unit and limits; `nil` when the rule has none.
    var parameter: (title: LocalizedStringKey, unit: Unit, range: ClosedRange<Double>, step: Double)? {
        switch self {
        case .lateRent: ("rule.param.late_day", .dayOfMonth, 1...28, 1)
        case .expectedRent: ("rule.param.digest_day", .dayOfMonth, 1...28, 1)
        case .upcomingExpense: ("rule.param.lead", .days, 0...30, 1)
        case .utilityIncrease: ("rule.param.increase", .percent, 5...100, 5)
        case .suppliesGap: ("rule.param.gap", .percent, 5...100, 5)
        case .vacancy: ("rule.param.vacant", .days, 7...180, 7)
        case .contractEnding: ("rule.param.ending", .days, 30...180, 15)
        case .rentUpdate: ("rule.param.update", .days, 15...90, 5)
        case .depositFiling: ("rule.param.filing", .days, 7...90, 1)
        case .unpaidExpense, .depositReturn: nil
        }
    }

    var defaultParam: Double {
        switch self {
        case .lateRent: 5
        case .expectedRent: 1
        case .upcomingExpense: 7
        case .utilityIncrease: 20
        case .suppliesGap: 15
        case .vacancy: 30
        case .contractEnding: 90
        case .rentUpdate: 45
        case .depositFiling: 30
        case .unpaidExpense, .depositReturn: 0
        }
    }

    /// Whether the rule can send a notification. The others react to data the landlord has
    /// just entered, so a notification would only repeat what is already on screen.
    var canNotify: Bool {
        switch self {
        case .unpaidExpense, .utilityIncrease, .suppliesGap, .depositReturn: false
        default: true
        }
    }

    var defaultNotify: Bool { canNotify }

    enum Group: CaseIterable {
        case rent, expenses, contracts
        var title: LocalizedStringKey {
            switch self {
            case .rent: "rule.group.rent"
            case .expenses: "rule.group.expenses"
            case .contracts: "rule.group.contracts"
            }
        }
    }

    var group: Group {
        switch self {
        case .lateRent, .expectedRent: .rent
        case .upcomingExpense, .unpaidExpense, .utilityIncrease, .suppliesGap: .expenses
        case .vacancy, .contractEnding, .rentUpdate, .depositReturn, .depositFiling: .contracts
        }
    }
}

struct AlertRule: Codable, Hashable {
    var enabled = true
    var notify = true
    var param = 0.0
}

@MainActor
@Observable
final class AlertConfig {
    static let shared = AlertConfig()
    private static let key = "alert_rules_v1"
    private static let timeKey = "alert_time_v1"

    private(set) var rules: [AlertRuleKind: AlertRule] = [:]
    /// Changes whenever a rule changes: lets the alerts that were computed with the old rules be discarded.
    private(set) var revision = 0
    /// Time of day of every notification: minutes after midnight.
    var minutes: Int { didSet { UserDefaults.standard.set(minutes, forKey: Self.timeKey) } }

    private init() {
        minutes = UserDefaults.standard.object(forKey: Self.timeKey) as? Int ?? 10 * 60
        let saved = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([AlertRuleKind: AlertRule].self, from: $0) } ?? [:]
        for kind in AlertRuleKind.allCases {
            rules[kind] = saved[kind] ?? Self.defaultRule(kind)
        }
    }

    static func defaultRule(_ kind: AlertRuleKind) -> AlertRule {
        AlertRule(enabled: true, notify: kind.defaultNotify, param: kind.defaultParam)
    }

    func rule(_ kind: AlertRuleKind) -> AlertRule { rules[kind] ?? Self.defaultRule(kind) }
    func isOn(_ kind: AlertRuleKind) -> Bool { rule(kind).enabled }
    func shouldNotify(_ kind: AlertRuleKind) -> Bool { kind.canNotify && rule(kind).enabled && rule(kind).notify }

    func update(_ kind: AlertRuleKind, _ change: (inout AlertRule) -> Void) {
        var r = rule(kind)
        change(&r)
        rules[kind] = r
        revision += 1
        persist()
    }

    func reset() {
        for kind in AlertRuleKind.allCases { rules[kind] = Self.defaultRule(kind) }
        minutes = 10 * 60
        revision += 1
        persist()
    }

    var isDefault: Bool {
        minutes == 10 * 60 && AlertRuleKind.allCases.allSatisfy { rule($0) == Self.defaultRule($0) }
    }

    /// The notification time as a date today, for a time picker.
    var time: Date {
        get { Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date() }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            minutes = (c.hour ?? 10) * 60 + (c.minute ?? 0)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(rules) { UserDefaults.standard.set(data, forKey: Self.key) }
    }
}
