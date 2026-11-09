//
//  DemoData.swift
//  Renting
//
//  A realistic, fully invented portfolio (6 homes — by rooms, traditional and seasonal —,
//  13 rooms/units, 15 tenants past and present, ~2 years of collections, two managers on
//  commission and every kind of expense) so the app can be explored with data. Dates
//  are relative to today, so the demo never goes stale.
//

import Foundation

enum DemoData {

    static func make(now: Date = Date()) -> Snapshot {
        let cal = Calendar.current
        let current = MonthKey(now)
        func date(monthsAgo: Int, day: Int = 1) -> Date {
            let m = current.adding(-monthsAgo)
            return cal.date(from: DateComponents(year: m.year, month: m.month, day: day)) ?? now
        }

        var snap = Snapshot()
        snap.isDemo = true
        var filingCount = 0

        // MARK: Properties and units

        func addProperty(_ name: String, _ address: String, _ city: String, _ kind: RentalKind, construction: Double?, management: Management? = nil,
                         cadastral: Double, revised: Bool, expenses: Double? = nil, units: [(String, Double, Double?)]) -> (Property, [Unit]) {
            let p = Property(name: name, address: address, city: city, kind: kind, constructionValue: construction, management: management,
                             cadastralValue: cadastral, cadastralRevised: revised)
            let us = units.map { Unit(propertyID: p.id, name: $0.0, listRent: $0.1, sqm: $0.2, listExpenses: expenses) }
            snap.properties.append(p)
            snap.units.append(contentsOf: us)
            return (p, us)
        }

        let (granVia, gv) = addProperty("Piso Gran Vía", "Calle Gran Vía 14, 3ºB", "Madrid", .rooms, construction: 92_000, cadastral: 145_000, revised: false, expenses: 35,
                                        units: [("Habitación 1", 420, 14), ("Habitación 2", 390, 12), ("Habitación 3", 450, 16), ("Habitación 4", 410, 13), ("Habitación 5", 380, 11)])
        let (ruzafa, rz) = addProperty("Casa Ruzafa", "Calle Cádiz 31, 2º", "Valencia", .rooms, construction: 64_000, cadastral: 98_000, revised: true, expenses: 30,
                                       units: [("Habitación 1", 340, 12), ("Habitación 2", 360, 14), ("Habitación 3", 320, 11), ("Habitación 4", 300, 10)])
        let (triana, tr) = addProperty("Ático Triana", "Calle Betis 62, Ático", "Sevilla", .traditional, construction: 78_000, cadastral: 120_000, revised: true,
                                       units: [("Vivienda completa", 950, 85)])
        let (poblenou, pn) = addProperty("Apartamento Poblenou", "Carrer de Pere IV 120, 4-2", "Barcelona", .traditional, construction: 110_000,
                                         management: Management(name: "Agencia Eixample Rent", percent: 7, plusVAT: true), cadastral: 160_000, revised: false,
                                         units: [("Vivienda completa", 1150, 62)])
        let (santCugat, sc) = addProperty("Chalet Sant Cugat", "Carrer Major 8", "Sant Cugat del Vallès", .traditional, construction: 180_000, cadastral: 240_000, revised: true,
                                          units: [("Vivienda completa", 1650, 140)])
        let (malvarrosa, mv) = addProperty("Apartamento Malvarrosa", "Calle de la Reina 85, 1ºA", "Valencia", .seasonal, construction: 58_000,
                                           management: Management(name: "Mediterránea Temporada", percent: 10, plusVAT: true), cadastral: 85_000, revised: true,
                                           units: [("Vivienda completa", 1100, 55)])

        // MARK: Tenants

        func addTenant(_ name: String, unit: Unit, entry: Int, exit: Int? = nil, rent: Double, extras: Double = 0,
                       deposit: Double, guarantee: Double = 0, returned: Double? = nil, phone: String, contractMonths: Int = 12,
                       reduction: RentReduction? = nil, changes: [(monthsAgo: Int, from: Double, to: Double)] = [], filed: Bool = true, notes: String = "") {
            let entryDate = date(monthsAgo: entry)
            var t = Tenant(unitID: unit.id, name: name, phone: phone, email: name.lowercased().components(separatedBy: " ").joined(separator: ".").folding(options: .diacriticInsensitive, locale: nil) + "@example.com",
                           entryDate: entryDate, monthlyRent: rent, monthlyExpenses: extras, deposit: deposit, extraGuarantee: guarantee, notes: notes,
                           reduction: reduction)
            t.contractEnd = cal.date(byAdding: .month, value: contractMonths * max(1, (entry / contractMonths) + 1), to: entryDate)
            let seasonal = unit.propertyID == malvarrosa.id
            t.contract = ContractInfo(regime: seasonal ? .lauSeasonal : .lauHousing,
                                      term: seasonal ? .shortTerm : (contractMonths == 12 ? .annual : .multiYear),
                                      rentInsurance: name.count % 3 == 0)
            // Past rent updates, one per anniversary, with the index the contract follows.
            let index: RentIndex = unit.propertyID == malvarrosa.id ? .manual : (entryDate < RentReduction.newLawDate ? .ipc : .irav)
            t.rentChanges = changes.isEmpty ? nil : changes.enumerated().map { i, c in
                let effective = current.adding(-c.monthsAgo)
                return RentChange(effective: effective, previous: c.from, new: c.to, index: index,
                                  percent: ((c.to / c.from - 1) * 1000).rounded() / 10, cycle: i + 1,
                                  notifiedOn: cal.date(byAdding: .day, value: -40, to: effective.start))
            }
            if filed {
                filingCount += 1
                t.filing = DepositFiling(signedOn: entryDate, filedOn: cal.date(byAdding: .day, value: 12, to: entryDate),
                                         reference: String(format: "DEP-%04d-%03d", cal.component(.year, from: entryDate), 100 + filingCount * 7))
            }
            if let exit {
                t.exitDate = date(monthsAgo: exit, day: 28)
                t.contractEnd = t.exitDate
                t.depositReturned = returned
                if returned != nil { t.depositReturnDate = date(monthsAgo: max(0, exit - 1), day: 12) }
            }
            snap.tenants.append(t)
        }

        // Gran Vía (rooms)
        addTenant("Lucía Fernández", unit: gv[0], entry: 26, rent: 420, extras: 35, deposit: 420, phone: "+34 611 220 301", changes: [(14, 400, 410), (2, 410, 420)], notes: "Estudiante de máster. Paga siempre por Bizum.")
        addTenant("Marco Rossi", unit: gv[1], entry: 14, rent: 390, extras: 35, deposit: 390, phone: "+39 333 110 2244", changes: [(2, 381, 390)])
        addTenant("Sofía Martín", unit: gv[2], entry: 9, rent: 450, extras: 35, deposit: 450, guarantee: 450, phone: "+34 622 334 118", notes: "Garantía adicional: un mes extra en depósito.")
        addTenant("Pablo Ruiz", unit: gv[3], entry: 19, exit: 5, rent: 395, extras: 35, deposit: 395, returned: 395, phone: "+34 655 902 117")
        addTenant("Daniel Okafor", unit: gv[3], entry: 4, rent: 410, extras: 35, deposit: 410, phone: "+34 644 118 902", notes: "Septiembre pendiente: prometió pagar a final de mes.")
        addTenant("Iris Chen", unit: gv[4], entry: 12, exit: 2, rent: 380, extras: 35, deposit: 380, returned: 250, phone: "+34 677 556 410", notes: "Se descontaron 130 € por pintura de la habitación.")

        // Casa Ruzafa (rooms)
        addTenant("Ana Costa", unit: rz[0], entry: 20, rent: 340, extras: 30, deposit: 340, phone: "+351 912 345 678", changes: [(8, 332, 340)])
        addTenant("Jorge Silva", unit: rz[1], entry: 11, rent: 360, extras: 30, deposit: 360, phone: "+34 600 481 922")
        addTenant("Emma Müller", unit: rz[2], entry: 6, rent: 320, extras: 30, deposit: 320, guarantee: 320, phone: "+49 151 2345 6789", notes: "Erasmus. Contrato hasta final de curso.")
        addTenant("Carlos Peña", unit: rz[3], entry: 2, rent: 300, extras: 30, deposit: 300, phone: "+34 633 727 105", filed: false)

        // Traditional
        addTenant("Familia García-López", unit: tr[0], entry: 46, rent: 950, extras: 60, deposit: 950, guarantee: 1_900, phone: "+34 954 112 233", contractMonths: 60, changes: [(34, 880, 905), (22, 905, 930), (10, 930, 950)], notes: "Contrato firmado antes de la Ley de vivienda: reducción del 60 %. Aval bancario depositado. Actualización de renta por IPC en cada aniversario.")
        addTenant("Hannah Wright", unit: pn[0], entry: 13, rent: 1_150, extras: 0, deposit: 1_150, guarantee: 2_300, phone: "+44 7700 900123", contractMonths: 36, reduction: .tensioned90, notes: "Teletrabaja. Contrato de 3 años. Zona tensionada: renta un 6 % más baja que el contrato anterior.")
        addTenant("Roberto Navarro", unit: sc[0], entry: 31, exit: 2, rent: 1_650, extras: 0, deposit: 1_650, returned: 1_150, phone: "+34 935 887 120", contractMonths: 60, notes: "Fianza devuelta menos 500 € por reparación del jardín. Vivienda libre desde hace 2 meses.")

        // Seasonal: six-month stays, utilities charged as a flat amount
        addTenant("Tomás Herrera", unit: mv[0], entry: 11, exit: 5, rent: 1_050, extras: 80, deposit: 2_100, returned: 2_100, phone: "+34 691 204 377", contractMonths: 6, notes: "Ingeniero desplazado por un proyecto de seis meses.")
        addTenant("Elena Petrova", unit: mv[0], entry: 3, rent: 1_100, extras: 80, deposit: 2_200, phone: "+359 88 712 3456", contractMonths: 6, notes: "Investigadora visitante en la universidad. Contrato de temporada de seis meses.")

        // MARK: Payments — everyone paid up to last month, with a few real-life exceptions

        let last = current.adding(-1)
        for t in snap.tenants {
            var m = MonthKey(t.entryDate)
            let endMonth = t.exitDate.map { MonthKey($0) } ?? current
            while m <= endMonth && m <= current {
                var skip = false
                var rent = t.rent(in: m)
                var supplies = t.monthlyExpenses
                if t.name == "Daniel Okafor" && m == last { skip = true }
                if t.name == "Carlos Peña" && m == last { rent = 150; supplies = 0 }
                if m == current && ["Carlos Peña", "Jorge Silva", "Ana Costa"].contains(t.name) { skip = true }
                if !skip {
                    let day = 1 + t.name.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 4 }
                    let paidOn = cal.date(from: DateComponents(year: m.year, month: m.month, day: min(day, 5))) ?? now
                    snap.payments.append(Payment(id: Payment.stableID(tenant: t.id, month: m), tenantID: t.id, month: m, amount: rent + supplies, paidOn: min(paidOn, now), supplies: supplies,
                                            rentDue: t.rent(in: m), suppliesDue: t.monthlyExpenses))
                }
                m = m.adding(1)
            }
        }

        // MARK: Expenses

        let jan = MonthKey(year: current.year - 1, month: 1)
        func exp(_ p: Property, _ cat: ExpenseCategory, _ title: String, _ amount: Double, _ freq: Frequency, startMonth: Int = 1, once monthsAgo: Int? = nil) {
            let first: MonthKey = monthsAgo.map { current.adding(-$0) } ?? MonthKey(year: jan.year, month: startMonth)
            snap.expenses.append(Expense(propertyID: p.id, unitID: nil, category: cat, title: title, amount: amount, frequency: freq, firstMonth: first))
        }

        exp(granVia, .community, "Comunidad de propietarios", 180, .quarterly)
        exp(granVia, .ibi, "IBI", 640, .annual, startMonth: 10)
        exp(granVia, .garbageTax, "Tasa de basuras", 96, .annual, startMonth: 6)
        exp(granVia, .insurance, "Seguro del hogar", 310, .annual, startMonth: 3)
        exp(granVia, .manager, "Gestoría", 60, .monthly)
        exp(granVia, .electricity, "Luz", 160, .monthly)
        exp(granVia, .water, "Agua", 55, .monthly)
        exp(granVia, .internet, "Fibra", 45, .monthly)
        exp(granVia, .cleaning, "Limpieza zonas comunes", 80, .monthly)
        exp(granVia, .repairs, "Cambio de caldera", 380, .once, once: 6)

        exp(ruzafa, .community, "Comunidad de propietarios", 120, .quarterly)
        exp(ruzafa, .ibi, "IBI", 410, .annual, startMonth: 9)
        exp(ruzafa, .wasteTax, "Tasa de residuos", 88, .annual, startMonth: 4)
        exp(ruzafa, .insurance, "Seguro del hogar", 260, .annual, startMonth: 2)
        exp(ruzafa, .electricity, "Luz", 120, .monthly)
        exp(ruzafa, .water, "Agua", 40, .monthly)
        exp(ruzafa, .internet, "Fibra", 40, .monthly)
        exp(ruzafa, .repairs, "Persiana y cerradura", 220, .once, once: 3)

        exp(triana, .community, "Comunidad de propietarios", 95, .monthly)
        exp(triana, .ibi, "IBI", 520, .annual, startMonth: 11)
        exp(triana, .insurance, "Seguro del hogar", 280, .annual, startMonth: 5)
        exp(triana, .garbageTax, "Tasa de basuras", 110, .annual, startMonth: 7)
        exp(triana, .mortgageInterest, "Intereses hipoteca", 420, .monthly)
        exp(triana, .maintenance, "Mantenimiento aire acondicionado", 90, .annual, startMonth: 4)

        exp(poblenou, .community, "Comunidad de propietarios", 140, .monthly)
        exp(poblenou, .ibi, "IBI", 690, .annual, startMonth: 11)
        exp(poblenou, .insurance, "Seguro de impago", 300, .annual, startMonth: 1)
        exp(poblenou, .mortgageInterest, "Intereses hipoteca", 300, .monthly)

        exp(santCugat, .ibi, "IBI", 1_150, .annual, startMonth: 8)
        exp(santCugat, .community, "Urbanización", 160, .monthly)
        exp(santCugat, .insurance, "Seguro del hogar", 420, .annual, startMonth: 2)
        exp(santCugat, .maintenance, "Jardinero", 90, .monthly)
        exp(santCugat, .mortgageInterest, "Intereses hipoteca", 380, .monthly)
        exp(santCugat, .wasteTax, "Tasa de residuos", 175, .annual, startMonth: 5)

        exp(malvarrosa, .community, "Comunidad de propietarios", 70, .monthly)
        exp(malvarrosa, .ibi, "IBI", 380, .annual, startMonth: 9)
        exp(malvarrosa, .wasteTax, "Tasa de residuos", 90, .annual, startMonth: 4)
        exp(malvarrosa, .insurance, "Seguro del hogar", 190, .annual, startMonth: 6)
        exp(malvarrosa, .electricity, "Luz", 65, .monthly)
        exp(malvarrosa, .water, "Agua", 25, .monthly)
        exp(malvarrosa, .internet, "Fibra", 35, .monthly)

        // MARK: Expense payments — settled up to last month except one repair still owed;
        // this month only the direct debits have gone through so far.

        let directDebits: Set<ExpenseCategory> = [.community, .mortgageInterest, .insurance, .internet]
        for i in snap.expenses.indices {
            let e = snap.expenses[i]
            for m in e.dueMonths(through: current) {
                let paid = m < current ? e.title != "Persiana y cerradura" : directDebits.contains(e.category)
                if paid { snap.expenses[i].paidMonths.insert(m) }
            }
        }
        // Real utility bills: the electricity of Gran Vía keeps climbing (a heating-season spike this
        // month), the water of Ruzafa is a bit under plan. Utilities vary every month.
        for i in snap.expenses.indices where snap.expenses[i].category.isUtility && snap.expenses[i].frequency == .monthly {
            let e = snap.expenses[i]
            var actuals: [Int: Double] = [:]
            for (back, m) in (0...3).map({ ($0, current.adding(-$0)) }) where e.amount(in: m) > 0 {
                let planned = e.plannedAmount(in: m)
                switch (e.propertyID == granVia.id, e.category) {
                case (true, .electricity): actuals[m.id] = planned * [1.38, 1.04, 0.97, 1.02][back]
                case (_, .water) where e.propertyID == ruzafa.id: actuals[m.id] = planned * [0.9, 0.94, 0.92, 0.95][back]
                default: break
                }
            }
            snap.expenses[i].actuals = actuals.isEmpty ? nil : actuals.mapValues { ($0 * 100).rounded() / 100 }
        }
        for i in snap.properties.indices where snap.properties[i].management != nil {
            for back in 1...36 { snap.properties[i].management?.paidMonths.insert(current.adding(-back)) }
        }

        return snap
    }
}
