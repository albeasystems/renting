//
//  Compliance.swift
//  Renting
//
//  Two legal duties of a Spanish landlord that the app helps to keep:
//    • the legal fianza must be deposited with the authority; the app only asks whether it is,
//      and reminds after a number of days from move-in (an alert-rule setting, the same everywhere);
//    • the rent may only be updated once a year, with the contract's index, notified in
//      writing: it is due from the month after the notification (LAU art. 18).
//  The 2026 rent caps change often, so everything the app assumes is shown to the landlord,
//  dated, and can be overridden.
//

import Foundation

// MARK: - Reference values for the annual update

/// Rules of the rent update as of `asOf`. The decree-laws of 2026 (8/2026, 26/2026, 29/2026)
/// changed them several times and RDL 29/2026 still has to be validated by Congress, so the
/// values are only a suggestion: the landlord always sees and edits the percentage.
enum RentRules {
    private static func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    static let asOf = day(2026, 10, 22)

    /// The values below are a snapshot: the INE publishes a new IRAV every month and the 2026 decrees
    /// keep changing. After this many days the app stops suggesting them and says so.
    static let staleAfterDays = 40
    static var daysOld: Int { Calendar.current.dateComponents([.day], from: asOf, to: Date()).day ?? 0 }
    static var isStale: Bool { daysOld > staleAfterDays }

    /// Latest IRAV published by the INE: September 2026, published on 14/10/2026.
    static let iravPercent = 2.54
    static let iravMonth = MonthKey(year: 2026, month: 9)
    static let iravURL = URL(string: "https://www.ine.es/uc/oC7D0Ncd")!

    /// RDL 29/2026: without a new agreement, updates between these dates cannot exceed 2 %.
    static let decreeCap = 2.0
    static let decreeFrom = day(2026, 10, 8)
    static let decreeTo = day(2027, 12, 31)

    struct Cap {
        var percent: Double
        /// The IRAV is a ceiling for this update.
        var irav: Bool
        /// The decree's 2 % ceiling applies to this anniversary.
        var decree: Bool
    }

    /// The ceiling for an update on `anniversary`; `nil` when none applies (seasonal lets).
    static func cap(contractStart: Date, anniversary: Date, seasonal: Bool) -> Cap? {
        guard !seasonal else { return nil }
        let irav = contractStart >= RentReduction.newLawDate || anniversary >= decreeFrom
        let decree = anniversary >= decreeFrom && anniversary <= decreeTo
        guard irav || decree else { return nil }
        var percent = Double.infinity
        if irav { percent = min(percent, iravPercent) }
        if decree { percent = min(percent, decreeCap) }
        return Cap(percent: percent, irav: irav, decree: decree)
    }
}

// MARK: - Rent update

struct RentReview: Identifiable {
    let tenant: Tenant
    /// Contract year being updated: 1 = first anniversary.
    let cycle: Int
    let anniversary: Date
    let daysToAnniversary: Int
    var id: String { "\(tenant.id)\(cycle)" }
}

struct FilingInfo {
    var status: FilingStatus
    /// Date the deadline counts from.
    var signedOn: Date
    var deadline: Date?
}

extension RentalStore {
    /// How long before an anniversary the update shows up (alert rule), and how long after it stays.
    static var reviewLeadDays: Int { Int(AlertConfig.shared.rule(.rentUpdate).param) }
    static let reviewGraceDays = 60

    // MARK: Update index

    /// A LAU lease of a home as the tenant's permanent residence: the only kind under article 18
    /// (annual update with a ceiling) and eligible for the income-tax reduction. A seasonal home,
    /// or a contract the landlord marked as seasonal or under the Civil Code, is not.
    func isHousingLease(_ tenant: Tenant) -> Bool {
        guard propertyID(ofTenant: tenant).flatMap(property)?.kind != .seasonal else { return false }
        return (tenant.contract?.regime ?? .lauHousing) == .lauHousing
    }

    /// Not a housing lease: rent and updates are whatever the parties agreed.
    func isSeasonal(_ tenant: Tenant) -> Bool { !isHousingLease(tenant) }

    /// Contracts from 26 May 2023 follow the IRAV; older ones what was agreed (usually the
    /// CPI); seasonal lets are not under article 18, so whatever the parties agree.
    func automaticIndex(for tenant: Tenant) -> RentIndex {
        if isSeasonal(tenant) { return .manual }
        return tenant.entryDate >= RentReduction.newLawDate ? .irav : .ipc
    }

    func updateIndex(for tenant: Tenant) -> RentIndex { tenant.rentIndex ?? automaticIndex(for: tenant) }

    /// First month charged at the new rent: the month after the written notification, and
    /// never before the anniversary.
    func effectiveMonth(anniversary: Date, notifiedOn: Date) -> MonthKey {
        max(MonthKey(anniversary), MonthKey(notifiedOn).adding(1))
    }

    /// The update a tenant is due: its anniversary is near (or just passed) and the year has no
    /// update, nor a "kept" decision, recorded yet.
    func pendingReview(for tenant: Tenant, now: Date = Date()) -> RentReview? {
        guard tenant.isActive, updateIndex(for: tenant) != .none, !isSeasonal(tenant) else { return nil }
        let cal = Calendar.current
        let covered = Set((tenant.rentChanges ?? []).compactMap(\.cycle))
        for n in 1...60 {
            guard let anniversary = cal.date(byAdding: .year, value: n, to: tenant.entryDate) else { return nil }
            if let exit = tenant.exitDate, anniversary > exit { return nil }
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: anniversary)).day ?? 0
            if days < -Self.reviewGraceDays { continue }
            if covered.contains(n) { return nil }
            return days <= Self.reviewLeadDays ? RentReview(tenant: tenant, cycle: n, anniversary: anniversary, daysToAnniversary: days) : nil
        }
        return nil
    }

    /// The anniversary after the last recorded update (for the "next update" line).
    func nextAnniversary(of tenant: Tenant, now: Date = Date()) -> (cycle: Int, date: Date)? {
        let cal = Calendar.current
        for n in 1...60 {
            guard let date = cal.date(byAdding: .year, value: n, to: tenant.entryDate) else { return nil }
            if date >= cal.startOfDay(for: now) { return (n, date) }
        }
        return nil
    }

    func applyRentChange(_ change: RentChange, to tenant: Tenant) {
        var t = self.tenant(tenant.id) ?? tenant
        t.monthlyRent = change.new
        t.rentChanges = (t.rentChanges ?? []) + [change]
        save(t)
    }

    /// Undoes the latest update (a mistake): the rent goes back to what it was.
    func undoLastRentChange(of tenant: Tenant) {
        guard var t = self.tenant(tenant.id), let last = t.changes.last else { return }
        t.rentChanges?.removeAll { $0.id == last.id }
        t.monthlyRent = last.previous
        save(t)
    }

    // MARK: Fianza deposit

    /// Days after moving in by which the fianza should be deposited (setting of the alert rule).
    static var depositDays: Int { Int(AlertConfig.shared.rule(.depositFiling).param) }

    func filingInfo(for tenant: Tenant, now: Date = Date()) -> FilingInfo {
        let cal = Calendar.current
        let signed = tenant.filing?.signedOn ?? tenant.entryDate
        let deadline = tenant.filing?.customDeadline ?? cal.date(byAdding: .day, value: Self.depositDays, to: signed)
        func info(_ status: FilingStatus) -> FilingInfo { FilingInfo(status: status, signedOn: signed, deadline: deadline) }
        guard tenant.deposit > 0, tenant.depositReturned == nil, let deadline else { return info(.notApplicable) }
        if tenant.filing?.notRequired == true { return info(.exempt) }
        if let filed = tenant.filing?.filedOn { return info(.filed(filed)) }
        return info(cal.startOfDay(for: now) > cal.startOfDay(for: deadline) ? .overdue(deadline) : .pending(deadline))
    }

    /// Marks the fianza as deposited (today) or not deposited with the authority.
    func setDeposited(_ deposited: Bool, for tenant: Tenant) {
        guard var t = self.tenant(tenant.id) else { return }
        t.setDeposited(deposited)
        save(t)
    }

    // MARK: Contract end

    /// Days until an active tenant's contract ends (negative once it has) when that is within the
    /// notice period of the alert rule or already past; `nil` otherwise.
    func contractEndDays(_ tenant: Tenant, now: Date = Date()) -> Int? {
        guard tenant.isActive, let end = tenant.contractEnd else { return nil }
        let left = daysToDeadline(end, now: now)
        return left <= Int(AlertConfig.shared.rule(.contractEnding).param) ? left : nil
    }

    /// Days left until the deadline (negative once it has passed).
    func daysToDeadline(_ deadline: Date, now: Date = Date()) -> Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: deadline)).day ?? 0
    }
}
