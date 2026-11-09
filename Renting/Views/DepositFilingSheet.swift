//
//  DepositFilingSheet.swift
//  Renting
//
//  The legal fianza has to be deposited with the authority
//  (LAU additional provision 3). The landlord only says whether it is deposited (a switch on the
//  tenant); the deadline this line and the alerts use is a number of days after move-in.
//

import SwiftUI

/// One-line status of a tenant's deposit, coloured by urgency.
struct FilingStatusText: View {
    @Environment(RentalStore.self) private var store
    let info: FilingInfo

    var body: some View {
        switch info.status {
        case .filed(let d): Text("dep.status.filed \(d.short)").foregroundStyle(Color.income)
        case .pending(let d): Text("dep.status.pending \(d.short) \(store.daysToDeadline(d))").foregroundStyle(Color.gold)
        case .overdue(let d): Text("dep.status.overdue \(d.short)").foregroundStyle(Color.alert)
        case .exempt: Text("dep.status.exempt").foregroundStyle(.secondary)
        case .notApplicable: EmptyView()
        }
    }
}
