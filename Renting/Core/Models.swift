//
//  Models.swift
//  Renting
//
//  Domain model. Everything is a plain Codable value type persisted as one JSON
//  file on the device (see `RentalStore`): no account, no server.
//

import Foundation
import SwiftUI

// MARK: - Month key

/// A calendar month (year + month), the unit of every rent collection and expense.
struct MonthKey: Codable, Hashable, Comparable, Identifiable {
    var year: Int
    var month: Int   // 1...12

    var id: Int { year * 12 + month - 1 }

    init(year: Int, month: Int) {
        let index = year * 12 + month - 1
        self.year = index / 12
        self.month = index % 12 + 1
    }

    init(_ date: Date) {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        self.init(year: c.year ?? 2025, month: c.month ?? 1)
    }

    static var current: MonthKey { MonthKey(Date()) }

    var start: Date { Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date() }
    var end: Date { Calendar.current.date(byAdding: DateComponents(month: 1, second: -1), to: start) ?? start }

    func adding(_ months: Int) -> MonthKey { MonthKey(year: year, month: month + months) }
    func months(since other: MonthKey) -> Int { id - other.id }

    static func < (a: MonthKey, b: MonthKey) -> Bool { a.id < b.id }

    static func months(of year: Int) -> [MonthKey] { (1...12).map { MonthKey(year: year, month: $0) } }

    func title(locale: Locale = AppLanguage.shared.locale, short: Bool = false) -> String {
        start.formatted(.dateTime.locale(locale).month(short ? .abbreviated : .wide).year())
    }

    func monthName(locale: Locale = AppLanguage.shared.locale, narrow: Bool = false) -> String {
        start.formatted(.dateTime.locale(locale).month(narrow ? .narrow : .abbreviated))
    }
}

// MARK: - Property & unit

/// How a home is let: whole and long-term, room by room, or whole for a season
/// (students, workers on assignment… LAU art. 3: not the tenant's permanent home).
enum RentalKind: String, Codable, CaseIterable, Identifiable {
    case traditional, rooms, seasonal
    var id: String { rawValue }
    var label: LocalizedStringKey { LocalizedStringKey("kind." + rawValue) }
    var name: String { L("kind." + rawValue) }
    var footer: LocalizedStringKey { LocalizedStringKey("kind." + rawValue + ".footer") }
    var icon: String {
        switch self {
        case .traditional: "house.fill"
        case .rooms: "bed.double.fill"
        case .seasonal: "suitcase.fill"
        }
    }
}

/// A property manager or agency paid a percentage of the rent collected. The utilities
/// tenants pay on top of the rent never count towards the fee.
struct Management: Codable, Hashable {
    var name = ""
    /// Fee as a percentage of the rent: 8 means 8 %.
    var percent: Double
    /// The fee is invoiced plus VAT.
    var plusVAT = false
    /// Months whose fee has already been settled.
    var paidMonths: Set<MonthKey> = []

    static let vat = 0.21
    var rate: Double { percent / 100 * (plusVAT ? 1 + Self.vat : 1) }
}

struct Property: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var address: String
    var city: String
    var kind: RentalKind
    /// Construction value (cadastral or purchase, without land): base for the 3 %
    /// yearly building depreciation in the fiscal report. Optional.
    var constructionValue: Double?
    var notes = ""
    /// Manager charging a percentage of the rent; `nil` when the landlord self-manages.
    var management: Management?
    /// Cadastral value (valor catastral, from the IBI bill): base of the income imputed
    /// for the days the home is not let.
    var cadastralValue: Double?
    /// The cadastral value was revised in the last ten years: imputation at 1.1 % instead of 2 %.
    var cadastralRevised = false
    /// The landlord lives here (rooms let in their own home): nothing is imputed.
    var ownerResidence = false
}

extension Property {
    /// Data saved before the fiscal fields existed has no such keys.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        address = try c.decode(String.self, forKey: .address)
        city = try c.decode(String.self, forKey: .city)
        kind = try c.decode(RentalKind.self, forKey: .kind)
        constructionValue = try c.decodeIfPresent(Double.self, forKey: .constructionValue)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        management = try c.decodeIfPresent(Management.self, forKey: .management)
        cadastralValue = try c.decodeIfPresent(Double.self, forKey: .cadastralValue)
        cadastralRevised = try c.decodeIfPresent(Bool.self, forKey: .cadastralRevised) ?? false
        ownerResidence = try c.decodeIfPresent(Bool.self, forKey: .ownerResidence) ?? false
    }

    /// Yearly rate of imputed income on the cadastral value.
    var imputationRate: Double { cadastralRevised ? 0.011 : 0.02 }
}

/// A rentable unit: a room, or the whole home for traditional rentals.
struct Unit: Identifiable, Codable, Hashable {
    var id = UUID()
    var propertyID: UUID
    var name: String
    /// Asking monthly rent, used as a default for new tenants and for vacancy loss. Every tenant keeps
    /// the rent they signed: changing this affects only the next one.
    var listRent: Double
    var sqm: Double?
    /// What a tenant of this room usually contributes each month to utilities and shared costs, on top
    /// of the rent: the default for the next tenant. `nil` = not set.
    var listExpenses: Double?
}

// MARK: - Tenant

/// Spanish income-tax reduction on the net yield of letting a home as the tenant's
/// permanent residence (LIRPF art. 23.2, as amended by Ley 12/2023).
enum RentReduction: String, Codable, CaseIterable, Identifiable {
    /// Seasonal lets and anything that is not the tenant's permanent home.
    case none
    /// Contracts from 26 May 2023, general case.
    case general50
    /// Contracts signed before 26 May 2023 keep the previous 60 %.
    case legacy60
    /// Home rehabilitated in the two years before the contract.
    case rehab60
    /// Let for the first time in a stressed area to a tenant aged 18–35, or for social housing.
    case young70
    /// New contract in a stressed area with the rent lowered more than 5 %.
    case tensioned90

    var id: String { rawValue }
    var rate: Double {
        switch self {
        case .none: 0
        case .general50: 0.5
        case .legacy60, .rehab60: 0.6
        case .young70: 0.7
        case .tensioned90: 0.9
        }
    }
    var label: LocalizedStringKey { LocalizedStringKey("red." + rawValue) }
    var name: String { L("red." + rawValue) }
    var short: String { rate.formatted(.percent.precision(.fractionLength(0)).locale(AppLanguage.shared.locale)) }

    /// Contracts signed from this day follow Ley 12/2023.
    static let newLawDate = Calendar.current.date(from: DateComponents(year: 2023, month: 5, day: 26)) ?? .distantPast
}

enum DepositState: String, Codable {
    case held, returned, partial, withheld
}

// MARK: - Contract

/// The law a lease is under: it decides which rules the app applies to it.
enum ContractRegime: String, Codable, CaseIterable, Identifiable {
    /// LAU, a home let as the tenant's permanent residence: the annual update of article 18
    /// (IRAV) and the income-tax reduction apply.
    case lauHousing
    /// LAU, seasonal or other use than housing: rent and updates are whatever was agreed.
    case lauSeasonal
    /// Civil Code (a room in the landlord's own home, for instance): whatever was agreed.
    case civil

    var id: String { rawValue }
    var label: LocalizedStringKey { LocalizedStringKey("contract.regime." + rawValue) }
    var name: String { L("contract.regime." + rawValue) }
}

/// How long the lease runs.
enum ContractTerm: String, Codable, CaseIterable, Identifiable {
    case annual, multiYear, shortTerm, monthly

    var id: String { rawValue }
    var label: LocalizedStringKey { LocalizedStringKey("contract.term." + rawValue) }
    var name: String { L("contract.term." + rawValue) }
}

/// What kind of contract a tenant has. Optional on the tenant: older data has none.
struct ContractInfo: Codable, Hashable {
    var regime: ContractRegime
    var term: ContractTerm
    /// The rent is covered by a default insurance (seguro de impago).
    var rentInsurance: Bool
}

struct Tenant: Identifiable, Codable, Hashable {
    var id = UUID()
    var unitID: UUID
    var name: String
    var phone = ""
    var email = ""
    var entryDate: Date
    var exitDate: Date?
    var contractEnd: Date?
    /// Monthly rent.
    var monthlyRent: Double
    /// Monthly amount re-charged for expenses (utilities, community…) on top of the rent.
    var monthlyExpenses: Double = 0
    /// Security deposit (fianza).
    var deposit: Double = 0
    /// Extra guarantee (garantía adicional): bank guarantee, second deposit…
    var extraGuarantee: Double = 0
    var depositReturned: Double?
    var depositReturnDate: Date?
    var notes = ""
    /// Income-tax reduction regime of the contract; `nil` = automatic (see `RentalStore.reduction(for:)`).
    var reduction: RentReduction?
    /// Update clause of the contract; `nil` = automatic (see `RentalStore.updateIndex(for:)`).
    var rentIndex: RentIndex?
    /// Rent updates already applied. `monthlyRent` is always the latest rent.
    var rentChanges: [RentChange]?
    /// Whether the fianza has been deposited with the authority.
    var filing: DepositFiling?
    /// Law, duration and rent insurance of the contract; `nil` = not filled in.
    var contract: ContractInfo?

    var monthlyTotal: Double { monthlyRent + monthlyExpenses }

    /// Updates sorted by the month they take effect.
    var changes: [RentChange] { (rentChanges ?? []).sorted { $0.effective < $1.effective } }

    /// The rent that applies in `month`: after an update the earlier months keep the old rent.
    func rent(in month: MonthKey) -> Double {
        changes.first { $0.effective > month }?.previous ?? monthlyRent
    }

    func monthlyTotal(in month: MonthKey) -> Double { rent(in: month) + monthlyExpenses }
    var isActive: Bool { exitDate.map { $0 > Date() } ?? true }

    /// Whether the tenant lives in the unit during `month` (any day counts).
    func isActive(in month: MonthKey) -> Bool {
        guard MonthKey(entryDate) <= month else { return false }
        if let exitDate, MonthKey(exitDate) < month { return false }
        return true
    }

    var depositState: DepositState {
        guard let returned = depositReturned else { return .held }
        if returned >= deposit { return .returned }
        return returned <= 0 ? .withheld : .partial
    }

    var depositOutstanding: Double { max(0, deposit - (depositReturned ?? 0)) }

    /// Marks the fianza as deposited with the authority (today, unless it already has a date) or not.
    mutating func setDeposited(_ deposited: Bool) {
        var f = filing ?? DepositFiling()
        f.filedOn = deposited ? (f.filedOn ?? Date()) : nil
        if deposited { f.notRequired = false }
        filing = f
    }
}

extension Tenant {
    /// A tenant about to move into `unit`: the room's rent and utilities are where they start. They are
    /// copied, so the tenant keeps them whatever the room's asking price does afterwards.
    static func starting(in unit: Unit, on date: Date = Date()) -> Tenant {
        Tenant(unitID: unit.id, name: "", entryDate: date, monthlyRent: unit.listRent, monthlyExpenses: unit.listExpenses ?? 0)
    }
}

// MARK: - Fianza deposit with the authority

/// Where a tenant's fianza stands. The landlord only says whether it is deposited; the deadline is a
/// number of days after moving in (an alert-rule setting), the same wherever the home is.
struct DepositFiling: Codable, Hashable {
    /// Contract signing date: the deadline counts from here (the entry date when empty).
    var signedOn: Date?
    var filedOn: Date?
    var reference = ""
    /// Marked as not applicable.
    var notRequired = false
    /// A deadline typed by the landlord, overriding the rule.
    var customDeadline: Date?
}

enum FilingStatus: Equatable {
    case notApplicable
    case exempt
    case filed(Date)
    case pending(Date)
    case overdue(Date)
}

// MARK: - Rent update (IRAV / IPC)

/// The clause of the contract that decides how the rent is updated each year.
enum RentIndex: String, Codable, CaseIterable, Identifiable {
    /// Índice de Referencia para la Actualización de los contratos de Arrendamiento de Vivienda (INE).
    case irav
    case ipc
    /// A fixed percentage written in the contract.
    case fixed
    /// A percentage agreed between the parties (seasonal lets, new agreements).
    case manual
    /// No express clause: by law the rent cannot be updated.
    case none

    var id: String { rawValue }
    var label: LocalizedStringKey { LocalizedStringKey("idx." + rawValue) }
    var name: String { L("idx." + rawValue) }
}

struct RentChange: Codable, Hashable, Identifiable {
    var id = UUID()
    /// First month charged at the new rent.
    var effective: MonthKey
    var previous: Double
    var new: Double
    var index: RentIndex
    /// Percentage applied; 0 when the rent was kept.
    var percent: Double
    /// Contract year this update belongs to (1 = first anniversary); `nil` for a manual change.
    var cycle: Int?
    var notifiedOn: Date?
}

// MARK: - Payment (the "check" in the calendar)

struct Payment: Identifiable, Codable, Hashable {
    var id = UUID()
    var tenantID: UUID
    var month: MonthKey
    /// Everything paid for the month: rent plus utilities.
    var amount: Double
    var paidOn: Date
    /// Part of `amount` paid for utilities. `nil` in payments saved before rent and
    /// utilities were split: the rent is then considered paid first.
    var supplies: Double?
    /// What was due for the month when the payment was recorded (rent and utilities). Kept so
    /// that raising the rent or the utilities later does not turn months already paid into
    /// "partial". `nil` in older payments: the current amounts are used.
    var rentDue: Double?
    var suppliesDue: Double?
}

// MARK: - Expenses

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case community, manager, garbageTax, wasteTax, ibi, insurance, rentInsurance
    case electricity, water, gas, internet
    case repairs, maintenance, cleaning, mortgageInterest, furnishings, other

    var id: String { rawValue }
    var label: LocalizedStringKey { LocalizedStringKey("cat." + rawValue) }
    var name: String { L("cat." + rawValue) }

    var icon: String {
        switch self {
        case .community: "building.2.fill"
        case .manager: "person.text.rectangle.fill"
        case .garbageTax, .wasteTax: "trash.fill"
        case .ibi: "building.columns.fill"
        case .insurance: "shield.fill"
        case .rentInsurance: "shield.lefthalf.filled"
        case .electricity: "bolt.fill"
        case .water: "drop.fill"
        case .gas: "flame.fill"
        case .internet: "wifi"
        case .repairs: "wrench.and.screwdriver.fill"
        case .maintenance: "gearshape.fill"
        case .cleaning: "sparkles"
        case .mortgageInterest: "percent"
        case .furnishings: "chair.lounge.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .community, .manager: .indigo
        case .garbageTax, .wasteTax, .ibi: .brown
        case .insurance: .teal
        case .rentInsurance: .mint
        case .electricity: .yellow
        case .water: .blue
        case .gas: .orange
        case .internet: .cyan
        case .repairs, .maintenance: .red
        case .cleaning: .mint
        case .mortgageInterest: .purple
        case .furnishings: .pink
        case .other: .gray
        }
    }

    /// Marked as deductible in the fiscal report until the landlord changes it.
    var deductibleByDefault: Bool { [.community, .ibi, .garbageTax, .wasteTax, .manager].contains(self) }

    /// Usually deductible as well in the Spanish income-tax return: shown as a hint.
    var usuallyDeductible: Bool { [.insurance, .rentInsurance, .mortgageInterest, .repairs, .maintenance].contains(self) }

    /// Bills that the utilities charged to tenants on top of the rent are meant to cover.
    var isUtility: Bool { [.electricity, .water, .gas, .internet].contains(self) }

    /// Typical frequency, used to prefill the form.
    var defaultFrequency: Frequency {
        switch self {
        case .ibi, .insurance, .rentInsurance, .wasteTax, .garbageTax: .annual
        case .community: .quarterly
        case .repairs, .furnishings, .maintenance: .once
        default: .monthly
        }
    }
}

enum Frequency: String, Codable, CaseIterable, Identifiable {
    case monthly, quarterly, annual, once
    var id: String { rawValue }
    var label: LocalizedStringKey { LocalizedStringKey("freq." + rawValue) }
    var name: String { L("freq." + rawValue) }
    var step: Int? {
        switch self {
        case .monthly: 1
        case .quarterly: 3
        case .annual: 12
        case .once: nil
        }
    }
}

struct Expense: Identifiable, Codable, Hashable {
    var id = UUID()
    var propertyID: UUID
    /// `nil` = the whole property (split between its units); otherwise one unit only.
    var unitID: UUID?
    var category: ExpenseCategory
    var title: String
    var amount: Double
    var frequency: Frequency
    /// First month it is charged; quarterly and annual expenses repeat from here.
    var firstMonth: MonthKey
    var lastMonth: MonthKey?
    /// Months in which this expense has already been paid.
    var paidMonths: Set<MonthKey> = []
    /// What the bill of a month really was (`MonthKey.id` → amount), when it differs from the
    /// planned `amount`: utilities vary every month, and the alerts watch those variations.
    var actuals: [Int: Double]?

    /// Amount charged in `month` (0 when nothing falls due): the actual bill when recorded.
    func amount(in month: MonthKey) -> Double {
        let planned = plannedAmount(in: month)
        guard planned > 0 else { return 0 }
        return actuals?[month.id] ?? planned
    }

    func hasActual(in month: MonthKey) -> Bool { plannedAmount(in: month) > 0 && actuals?[month.id] != nil }

    /// Amount expected in `month` before any actual bill is recorded.
    func plannedAmount(in month: MonthKey) -> Double {
        guard month >= firstMonth else { return 0 }
        if let lastMonth, month > lastMonth { return 0 }
        let diff = month.months(since: firstMonth)
        guard let step = frequency.step else { return diff == 0 ? amount : 0 }
        return diff % step == 0 ? amount : 0
    }

    /// Annualised cost, for "what does this cost me per year".
    var yearlyCost: Double {
        switch frequency {
        case .monthly: amount * 12
        case .quarterly: amount * 4
        case .annual: amount
        case .once: amount
        }
    }

    /// Months in which the expense falls due, from its start up to `month` included.
    func dueMonths(through month: MonthKey) -> [MonthKey] {
        guard firstMonth <= month else { return [] }
        return (0...month.months(since: firstMonth)).map { firstMonth.adding($0) }.filter { amount(in: $0) > 0 }
    }
}

extension Expense {
    /// Data saved before expense payments were tracked has no `paidMonths`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        propertyID = try c.decode(UUID.self, forKey: .propertyID)
        unitID = try c.decodeIfPresent(UUID.self, forKey: .unitID)
        category = try c.decode(ExpenseCategory.self, forKey: .category)
        title = try c.decode(String.self, forKey: .title)
        amount = try c.decode(Double.self, forKey: .amount)
        frequency = try c.decode(Frequency.self, forKey: .frequency)
        firstMonth = try c.decode(MonthKey.self, forKey: .firstMonth)
        lastMonth = try c.decodeIfPresent(MonthKey.self, forKey: .lastMonth)
        paidMonths = try c.decodeIfPresent(Set<MonthKey>.self, forKey: .paidMonths) ?? []
        actuals = try c.decodeIfPresent([Int: Double].self, forKey: .actuals)
    }
}

// MARK: - Charge

/// One expense falling due in one month: an occurrence of a recorded expense, or the
/// manager's fee on the rent collected that month. The unit of "mark as paid".
struct Charge: Identifiable, Hashable {
    enum Source: Hashable {
        case expense(UUID)
        /// The manager fee of a property.
        case management(UUID)
    }

    let source: Source
    let month: MonthKey
    let propertyID: UUID
    let category: ExpenseCategory
    let title: String
    let amount: Double
    let isPaid: Bool
    /// What was planned for the month, and whether `amount` is the actual bill instead.
    var planned: Double = 0
    var isActual = false

    var id: String {
        switch source {
        case .expense(let id): "e\(id.uuidString)-\(month.id)"
        case .management(let id): "m\(id.uuidString)-\(month.id)"
        }
    }

    func status(now: Date = Date()) -> CollectionStatus {
        if isPaid { return .paid }
        return month < MonthKey(now) ? .overdue : .upcoming
    }
}

// MARK: - Snapshot

struct Snapshot: Codable {
    var properties: [Property] = []
    var units: [Unit] = []
    var tenants: [Tenant] = []
    var payments: [Payment] = []
    var expenses: [Expense] = []
    var isDemo = false
    /// Expense categories counted as deductible in the fiscal report; `nil` until the
    /// landlord changes one, meaning `ExpenseCategory.deductibleByDefault`.
    var deductible: Set<ExpenseCategory>?
}
