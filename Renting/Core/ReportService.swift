//
//  ReportService.swift
//  Renting
//
//  Yearly fiscal report (PDF) and a full ledger (CSV), both built on-device, following
//  the Spanish income-tax rules for letting homes:
//    • income = rent collected (utilities charged on top are left out);
//    • deductible = the categories the landlord marks, only for the days the home was
//      let (the manager's commission only exists on rent, so it is never prorated);
//    • 3 % building depreciation, also for the days let;
//    • reduction on a positive net yield per the contract's regime (50–90 %, none for
//      seasonal lets), split between contracts by the rent each one brought in;
//    • imputed income for the days not let: 1.1 % or 2 % of the cadastral value.
//  It is a working summary, not tax advice.
//

import Foundation
import UIKit

@MainActor
enum ReportService {

    // MARK: Fiscal figures

    struct TenantFigures: Identifiable {
        let id: UUID
        var name: String
        var unit: String
        /// Rent collected in the year.
        var rent: Double
        var reduction: RentReduction
    }

    struct PropertyFigures {
        var property: Property
        /// Rent collected: the fiscal income.
        var income: Double
        /// Utilities tenants paid on top of the rent: shown, never added to income.
        var supplies: Double
        /// Rent due in the year and not collected.
        var unpaidRent: Double
        /// Categories marked as deductible, whole-year amounts.
        var expensesByCategory: [(category: ExpenseCategory, amount: Double)]
        /// Sum of `expensesByCategory`.
        var markedExpenses: Double
        /// The deductible part: expenses of the days the home was let.
        var expenses: Double
        /// Expenses of categories not marked as deductible.
        var otherExpenses: Double
        var depreciation: Double
        /// Reduction for letting a permanent home, on the positive net yield.
        var reduction: Double
        /// Share of the year the home was let (1 = every room all year).
        var rentedShare: Double
        /// Income imputed for the days not let.
        var imputed: Double
        var tenants: [TenantFigures]

        var vacantExpenses: Double { markedExpenses - expenses }
        var net: Double { income - expenses - depreciation }
        var netReduced: Double { net - reduction }
        var vacantDays: Int { Int(((1 - rentedShare) * Double(RentalStore.days(in: year))).rounded()) }
        var year: Int
    }

    /// 3 % of the construction value, for the share of the year the home was let.
    static func depreciation(of property: Property, year: Int, store: RentalStore) -> Double {
        guard let value = property.constructionValue, value > 0 else { return 0 }
        return value * 0.03 * store.rentedShare(property: property.id, year: year)
    }

    static func figures(year: Int, store: RentalStore, property: UUID? = nil) -> [PropertyFigures] {
        let months = MonthKey.months(of: year)
        let unitOfExpense = Dictionary(store.data.expenses.map { ($0.id, $0.unitID) }, uniquingKeysWith: { a, _ in a })
        return store.data.properties.filter { property == nil || $0.id == property }.map { p in
            let totals = store.totals(year: year, property: p.id)
            let share = store.rentedShare(property: p.id, year: year)

            // Deductible expenses, kept only for the days let.
            let deductible = store.expenseBreakdown(year: year, property: p.id).filter { store.isDeductible($0.category) }
            let marked = deductible.reduce(0) { $0 + $1.amount }
            var prorated = 0.0
            for m in months {
                for c in store.charges(in: m, property: p.id) where store.isDeductible(c.category) {
                    switch c.source {
                    case .management:
                        prorated += c.amount
                    case .expense(let id):
                        let unit = unitOfExpense[id] ?? nil
                        prorated += c.amount * (unit.map { store.rentedShare(unit: $0, year: year) } ?? share)
                    }
                }
            }

            let tenants = store.data.tenants.filter { store.propertyID(ofTenant: $0) == p.id }
            let rows: [TenantFigures] = tenants.compactMap { t in
                let rent = months.reduce(0.0) { $0 + (store.payment(of: t.id, in: $1).map { store.split($0).rent } ?? 0) }
                guard rent > 0 else { return nil }
                return TenantFigures(id: t.id, name: t.name, unit: store.unitLabel(t), rent: rent, reduction: store.reduction(for: t))
            }.sorted { $0.rent > $1.rent }
            let unpaid = tenants.reduce(0.0) { acc, t in
                acc + months.filter { t.isActive(in: $0) }.reduce(0.0) { $0 + store.unpaidRent(of: t, in: $1) }
            }

            let dep = depreciation(of: p, year: year, store: store)
            let net = totals.rent - prorated - dep
            let rentSum = rows.reduce(0) { $0 + $1.rent }
            let reduction = net > 0 && rentSum > 0 ? rows.reduce(0) { $0 + net * $1.rent / rentSum * $1.reduction.rate } : 0
            let imputed = p.ownerResidence ? 0 : (p.cadastralValue ?? 0) * p.imputationRate * (1 - share)

            return PropertyFigures(property: p, income: totals.rent, supplies: totals.supplies, unpaidRent: unpaid,
                                   expensesByCategory: deductible, markedExpenses: marked, expenses: prorated,
                                   otherExpenses: totals.expenses - marked, depreciation: dep, reduction: reduction,
                                   rentedShare: share, imputed: imputed, tenants: rows, year: year)
        }
    }

    /// "73 days not let · 1.1 % of €145,000".
    static func imputationDetail(_ f: PropertyFigures) -> String {
        let rate = f.property.imputationRate.formatted(.percent.precision(.fractionLength(0...1)).locale(AppLanguage.shared.locale))
        return L("fiscal.vacant_days_detail", f.vacantDays, rate, (f.property.cadastralValue ?? 0).money)
    }

    // MARK: PDF

    static func makePDF(year: Int, store: RentalStore, property: UUID? = nil) -> URL? {
        let figs = figures(year: year, store: store, property: property)
        guard !figs.isEmpty else { return nil }

        let title = PDFCanvas.font(22, .bold)
        let h2 = PDFCanvas.font(14, .semibold)
        let body = PDFCanvas.font(10.5)
        let bold = PDFCanvas.font(10.5, .semibold)
        let small = PDFCanvas.font(8.5)
        let brand = PDFCanvas.brand

        let data = PDFCanvas.render(page: CGRect(x: 0, y: 0, width: 595, height: 842), margin: 40) { c in
            // Cover / summary page
            c.newPage()
            c.bar()
            c.text(L("pdf.title", "\(year)"), font: title)
            c.space(2)
            c.text(L("pdf.generated", Date().short), font: small, color: .secondaryLabel)
            c.space(14)

            func sum(_ value: (PropertyFigures) -> Double) -> Double { figs.reduce(0) { $0 + value($1) } }
            let net = sum(\.net)
            let reduction = sum(\.reduction)
            c.text(L("pdf.summary"), font: h2, color: brand); c.space(6)
            c.row(L("pdf.income"), sum(\.income).moneyExact, font: bold)
            c.row(L("pdf.expenses"), (-sum(\.expenses)).moneyExact, sub: sum(\.vacantExpenses) > 0.5 ? L("pdf.vacant_expenses_note", sum(\.vacantExpenses).moneyExact) : nil)
            c.row(L("pdf.depreciation"), (-sum(\.depreciation)).moneyExact)
            c.rule()
            c.row(L("pdf.net"), net.moneyExact, font: bold)
            c.row(L("fiscal.reduction"), (-reduction).moneyExact)
            c.rule()
            c.row(L("fiscal.net_reduced"), (net - reduction).moneyExact, font: bold, color: brand)
            if sum(\.imputed) > 0 { c.row(L("fiscal.imputed"), sum(\.imputed).moneyExact, font: bold) }
            c.space(6)
            if sum(\.supplies) > 0 { c.row(L("pdf.supplies_excluded"), sum(\.supplies).moneyExact, font: small, color: .secondaryLabel) }
            if sum(\.unpaidRent) > 0 { c.row(L("pdf.unpaid_rent"), sum(\.unpaidRent).moneyExact, font: small, color: .secondaryLabel) }
            c.space(14)

            c.text(L("pdf.by_property"), font: h2, color: brand); c.space(6)
            for f in figs {
                c.row(f.property.name, f.netReduced.moneyExact, font: bold,
                      sub: "\(f.property.city) · \(L("pdf.income")) \(f.income.money) · \(L("pdf.expenses")) \(f.expenses.money)")
            }

            // One section per property
            for f in figs {
                c.newPage()
                c.text(f.property.name, font: title)
                c.text("\(f.property.address), \(f.property.city) · \(f.property.kind.name)", font: small, color: .secondaryLabel)
                c.space(12)

                c.text(L("pdf.income_by_tenant"), font: h2, color: brand); c.space(6)
                if f.tenants.isEmpty { c.text(L("pdf.none"), font: body, color: .secondaryLabel) }
                for t in f.tenants { c.row(t.name, t.rent.moneyExact, sub: "\(t.unit) · \(L("fiscal.reduction")) \(t.reduction.short)") }
                c.rule()
                c.row(L("pdf.income"), f.income.moneyExact, font: bold)
                if f.supplies > 0 { c.row(L("pdf.supplies_excluded"), f.supplies.moneyExact, font: small, color: .secondaryLabel) }
                c.space(12)

                c.text(L("pdf.expenses_by_category"), font: h2, color: brand); c.space(6)
                if f.expensesByCategory.isEmpty { c.text(L("pdf.none"), font: body, color: .secondaryLabel) }
                for e in f.expensesByCategory {
                    let terms = e.category == .manager ? f.property.management.map { store.managementTerms($0) } : nil
                    c.row(e.category.name, (-e.amount).moneyExact, sub: terms)
                }
                if f.vacantExpenses > 0.5 { c.row(L("fiscal.vacant_expenses"), f.vacantExpenses.moneyExact, color: .secondaryLabel) }
                if f.depreciation > 0 { c.row(L("pdf.depreciation"), (-f.depreciation).moneyExact) }
                c.rule()
                c.row(L("pdf.net"), f.net.moneyExact, font: bold)
                c.row(L("fiscal.reduction"), (-f.reduction).moneyExact)
                c.rule()
                c.row(L("fiscal.net_reduced"), f.netReduced.moneyExact, font: bold, color: brand)
                if f.imputed > 0 { c.row(L("fiscal.imputed"), f.imputed.moneyExact, font: bold, sub: imputationDetail(f)) }
            }

            // Disclaimer on the last page
            c.ensure(60); c.space(16)
            c.text(L("pdf.disclaimer"), font: small, color: .secondaryLabel)
        }
        return PDFCanvas.write(data, name: "Renting-\(year).pdf")
    }

    // MARK: CSV

    static func makeCSV(year: Int, store: RentalStore, property: UUID? = nil) -> URL? {
        func esc(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        // Excel in regions with a decimal comma (Spain, Germany, France, Italy, Portugal…) expects ';'
        // between columns and ',' in numbers; and without the UTF-8 marker it garbles accents.
        let commaRegion = Locale.current.decimalSeparator == ","
        let sep = commaRegion ? ";" : ","
        func num(_ v: Double) -> String {
            let s = String(format: "%.2f", v)
            return commaRegion ? s.replacingOccurrences(of: ".", with: ",") : s
        }
        var lines = ["year,month,type,property,room,tenant,category,description,amount,deductible,paid".replacingOccurrences(of: ",", with: sep)]
        let months = MonthKey.months(of: year)

        for p in store.data.payments.sorted(by: { $0.month < $1.month }) where p.month.year == year {
            guard let t = store.tenant(p.tenantID), let u = store.unit(t.unitID), let prop = store.property(u.propertyID),
                  property == nil || prop.id == property else { continue }
            let parts = store.split(p)
            let base = [String(year), String(p.month.month), "income", esc(prop.name), esc(u.name), esc(t.name)]
            lines.append((base + ["rent", "", num(parts.rent), "", "yes"]).joined(separator: sep))
            if parts.supplies > 0 {
                lines.append((base + ["supplies", "", num(parts.supplies), "", "yes"]).joined(separator: sep))
            }
        }
        for m in months {
            for c in store.charges(in: m, property: property) {
                let prop = store.property(c.propertyID)?.name ?? ""
                var room = ""
                if case .expense(let id) = c.source { room = store.data.expenses.first { $0.id == id }?.unitID.flatMap { store.unit($0)?.name } ?? "" }
                lines.append([String(year), String(m.month), "expense", esc(prop), esc(room), "", c.category.rawValue, esc(c.title),
                              num(-c.amount), store.isDeductible(c.category) ? "yes" : "no", c.isPaid ? "yes" : "no"].joined(separator: sep))
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Renting-\(year).csv")
        do { try ("\u{FEFF}" + lines.joined(separator: "\n")).write(to: url, atomically: true, encoding: .utf8); return url } catch { return nil }
    }
}
