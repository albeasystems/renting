//
//  RentLetterService.swift
//  Renting
//
//  The written notification of the annual rent update (LAU art. 18.2): an A4 letter that
//  states the percentage applied, the index, the old and new rent and the month from
//  which the new rent is due. The law also accepts a note on the previous month's receipt.
//

import Foundation
import UIKit

extension Double {
    /// "2.54 %" in the app's language: the value is already a percentage.
    var percentText: String {
        (self / 100).formatted(.percent.precision(.fractionLength(0...2)).locale(AppLanguage.shared.locale))
    }
}

@MainActor
enum RentLetterService {

    static func make(tenant: Tenant, change: RentChange, store: RentalStore) -> URL? {
        guard let unit = store.unit(tenant.unitID), let property = store.property(unit.propertyID) else { return nil }
        let landlord = Landlord.current
        let notified = change.notifiedOn ?? Date()
        var address = "\(property.address), \(property.city)"
        if property.kind == .rooms { address += " · \(unit.name)" }

        let bold = PDFCanvas.font(11.5, .semibold)
        let body = PDFCanvas.font(11.5)
        let small = PDFCanvas.font(8.5)
        let label = PDFCanvas.font(8, .semibold)

        let data = PDFCanvas.render(page: CGRect(x: 0, y: 0, width: 595, height: 842), margin: 56) { c in
            c.newPage()
            c.bar()
            c.text(landlord.name.isEmpty ? "—" : landlord.name, font: bold)
            if !landlord.taxID.isEmpty { c.text("\(L("receipt.tax_id")) \(landlord.taxID)", font: small, color: .secondaryLabel) }
            c.space(16)
            c.text("\(property.city), \(notified.short)", font: body, align: c.rtl ? .left : .right)
            c.space(18)

            c.text(L("letter.to").uppercased(), font: label, color: .secondaryLabel)
            c.space(1)
            c.text(tenant.name, font: bold)
            c.text(address, font: body)
            c.space(20)

            c.text(L("letter.subject"), font: bold)
            c.space(14)
            c.text(L("letter.greeting", tenant.name), font: body)
            c.space(10)
            c.text(L("letter.body1", address, tenant.entryDate.short, change.percent.percentText, L("letter.idx." + change.index.rawValue)), font: body)
            c.space(16)

            c.rule(color: PDFCanvas.brand, lineWidth: 0.8)
            c.row(L("letter.previous"), change.previous.moneyExact, font: body)
            c.row(L("letter.variation"), "+" + change.percent.percentText, font: body)
            c.row(L("letter.new"), change.new.moneyExact, font: bold)
            c.row(L("letter.effective"), change.effective.title(), font: body, valueWidth: 150)
            c.rule(color: PDFCanvas.brand, lineWidth: 0.8)
            c.space(10)

            c.text(L("letter.body2", change.effective.title()), font: body)
            c.space(10)
            c.text(L("letter.body3"), font: body)
            c.space(22)
            c.text(L("letter.closing"), font: body)
            c.space(50)

            let lineWidth: CGFloat = 190
            let lineX = c.rtl ? c.margin + c.width - lineWidth : c.margin
            let line = UIBezierPath()
            line.move(to: CGPoint(x: lineX, y: c.y))
            line.addLine(to: CGPoint(x: lineX + lineWidth, y: c.y))
            UIColor.label.setStroke(); line.lineWidth = 0.6; line.stroke()
            c.space(4)
            c.text(landlord.name.isEmpty ? L("receipt.signature") : landlord.name, font: small, color: .secondaryLabel, x: lineX, w: lineWidth, align: .center)

            c.y = c.bottom - 24
            c.text(L("letter.footer"), font: PDFCanvas.font(7.5), color: .tertiaryLabel)
        }

        let name = tenant.name.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "-")
        let file = "\(L("letter.file"))-\(name)-\(String(format: "%04d-%02d", change.effective.year, change.effective.month)).pdf"
        return PDFCanvas.write(data, name: file, folder: "Letters")
    }
}
