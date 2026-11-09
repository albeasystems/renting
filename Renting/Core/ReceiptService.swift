//
//  ReceiptService.swift
//  Renting
//
//  Rent receipt (recibo de alquiler) for one tenant and month, as an A5 PDF ready to
//  send by WhatsApp or mail. Spanish law (LAU art. 17.4) asks the landlord for a
//  receipt that states each concept separately and the rent in force, so rent and
//  utilities are always on their own lines.
//

import Foundation
import UIKit

/// The landlord's name and tax ID, printed on receipts. Kept on the device only.
struct Landlord {
    static let nameKey = "landlord_name"
    static let taxIDKey = "landlord_tax_id"

    var name: String
    var taxID: String

    static var current: Landlord {
        Landlord(name: UserDefaults.standard.string(forKey: nameKey) ?? "", taxID: UserDefaults.standard.string(forKey: taxIDKey) ?? "")
    }
}

@MainActor
enum ReceiptService {

    /// "202610-3FA2": year and month of the rent plus the start of the payment's ID.
    static func number(of payment: Payment) -> String {
        String(format: "%04d%02d-", payment.month.year, payment.month.month) + payment.id.uuidString.prefix(4)
    }

    static func make(tenant: Tenant, month: MonthKey, store: RentalStore) -> URL? {
        guard let payment = store.payment(of: tenant.id, in: month),
              let unit = store.unit(tenant.unitID), let property = store.property(unit.propertyID) else { return nil }
        let parts = store.split(payment)
        let landlord = Landlord.current
        let pending = max(0, store.due(of: tenant, in: month) - payment.amount)

        let title = PDFCanvas.font(17, .bold)
        let label = PDFCanvas.font(8, .semibold)
        let body = PDFCanvas.font(10.5)
        let bold = PDFCanvas.font(10.5, .semibold)
        let small = PDFCanvas.font(8.5)

        let data = PDFCanvas.render(page: CGRect(x: 0, y: 0, width: 420, height: 595), margin: 32) { c in
            c.newPage()
            c.bar()
            c.row(L("receipt.title"), "Nº \(number(of: payment))", font: title, valueWidth: 170)
            c.text(L("receipt.period", month.title()), font: body, color: .secondaryLabel)
            c.space(16)

            @MainActor func field(_ name: String, _ value: String) {
                c.text(name.uppercased(), font: label, color: .secondaryLabel)
                c.space(1)
                c.text(value, font: body)
                c.space(8)
            }
            var landlordLine = landlord.name.isEmpty ? "—" : landlord.name
            if !landlord.taxID.isEmpty { landlordLine += " · \(L("receipt.tax_id")) \(landlord.taxID)" }
            field(L("receipt.landlord"), landlordLine)
            field(L("receipt.tenant"), tenant.name)
            var home = "\(property.address), \(property.city)"
            if property.kind == .rooms { home += " · \(unit.name)" }
            field(L("receipt.home"), home)

            c.space(4)
            c.text(L("receipt.concepts").uppercased(), font: label, color: PDFCanvas.brand)
            c.space(4)
            c.row(L("receipt.rent", month.title()), parts.rent.moneyExact, font: body)
            if parts.supplies > 0 || tenant.monthlyExpenses > 0 {
                c.row(L("receipt.supplies"), parts.supplies.moneyExact, font: body)
            }
            c.rule(color: .label, lineWidth: 0.8)
            c.row(L("receipt.total"), payment.amount.moneyExact, font: bold)
            c.space(8)
            c.row(L("receipt.current_rent"), L("receipt.per_month", store.rentDue(of: tenant, in: month).moneyExact), font: small, color: .secondaryLabel, valueWidth: 140)
            c.row(L("receipt.paid_on"), payment.paidOn.short, font: small, color: .secondaryLabel, valueWidth: 140)
            if pending > 0.005 {
                c.row(L("receipt.pending"), pending.moneyExact, font: small, color: .systemRed, valueWidth: 140)
            }
            // The law also accepts the notice of an update as a note on the previous month's receipt.
            if let change = tenant.changes.first(where: { $0.effective > month && $0.percent > 0 }) {
                c.space(10)
                c.text(L("receipt.rent_notice", change.effective.title(), change.new.moneyExact), font: bold, color: PDFCanvas.brand)
            }

            c.space(22)
            c.text(L("receipt.received", property.city, Date().short), font: body)
            c.space(44)
            let lineWidth: CGFloat = 170
            let lineX = c.rtl ? c.margin : c.margin + c.width - lineWidth
            let line = UIBezierPath()
            line.move(to: CGPoint(x: lineX, y: c.y))
            line.addLine(to: CGPoint(x: lineX + lineWidth, y: c.y))
            UIColor.label.setStroke(); line.lineWidth = 0.6; line.stroke()
            c.space(4)
            c.text(landlord.name.isEmpty ? L("receipt.signature") : landlord.name, font: small, color: .secondaryLabel,
                   x: lineX, w: lineWidth, align: .center)

            c.y = c.bottom - 22
            c.text(L("receipt.legal"), font: PDFCanvas.font(7.5), color: .tertiaryLabel)
        }

        let tenantName = tenant.name.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "-")
        let file = "\(L("receipt.file"))-\(tenantName)-\(String(format: "%04d-%02d", month.year, month.month)).pdf"
        return PDFCanvas.write(data, name: file, folder: "Receipts")
    }
}
