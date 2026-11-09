//
//  PDFCanvas.swift
//  Renting
//
//  Minimal top-down text layout on a PDF page, shared by the fiscal report and the
//  rent receipts. Honours right-to-left languages and always draws in light colours,
//  whatever the app's appearance (a PDF is paper).
//

import UIKit

@MainActor
final class PDFCanvas {
    static let brand = UIColor(red: 0.06, green: 0.46, blue: 0.43, alpha: 1)
    nonisolated static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont { .systemFont(ofSize: size, weight: weight) }

    let page: CGRect
    let margin: CGFloat
    var y: CGFloat
    let rtl = AppLanguage.shared.isRightToLeft
    private let context: UIGraphicsPDFRendererContext

    var width: CGFloat { page.width - margin * 2 }
    var bottom: CGFloat { page.height - margin }

    private init(context: UIGraphicsPDFRendererContext, page: CGRect, margin: CGFloat) {
        self.context = context
        self.page = page
        self.margin = margin
        self.y = margin
    }

    /// Renders a document; `draw` must start with `newPage()`.
    static func render(page: CGRect, margin: CGFloat, _ draw: (PDFCanvas) -> Void) -> Data {
        var data = Data()
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            data = UIGraphicsPDFRenderer(bounds: page).pdfData { ctx in
                draw(PDFCanvas(context: ctx, page: page, margin: margin))
            }
        }
        return data
    }

    static func write(_ data: Data, name: String, folder: String? = nil) -> URL? {
        var dir = FileManager.default.temporaryDirectory
        if let folder {
            dir.appendPathComponent(folder, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let url = dir.appendingPathComponent(name)
        do { try data.write(to: url, options: .atomic); return url } catch { return nil }
    }

    func newPage() { context.beginPage(); y = margin }
    func ensure(_ h: CGFloat) { if y + h > bottom { newPage() } }
    func space(_ h: CGFloat) { y += h }

    func text(_ s: String, font: UIFont, color: UIColor = .label, x: CGFloat? = nil, w: CGFloat? = nil, align: NSTextAlignment = .natural) {
        let para = NSMutableParagraphStyle()
        para.alignment = align == .natural ? (rtl ? .right : .left) : align
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: para]
        let width = w ?? self.width
        let rect = (s as NSString).boundingRect(with: CGSize(width: width, height: 1000), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        (s as NSString).draw(in: CGRect(x: x ?? margin, y: y, width: width, height: rect.height), withAttributes: attrs)
        y += ceil(rect.height)
    }

    /// Two-column row: label on the leading side, amount on the trailing side.
    func row(_ label: String, _ value: String, font: UIFont = PDFCanvas.font(10.5), color: UIColor = .label, sub: String? = nil, valueWidth: CGFloat = 110) {
        ensure(16)
        let top = y
        let labelW = width - valueWidth - 8
        text(label, font: font, color: color, x: rtl ? margin + valueWidth + 8 : margin, w: labelW)
        let labelBottom = y
        y = top
        text(value, font: font, color: color, x: rtl ? margin : margin + labelW + 8, w: valueWidth, align: rtl ? .left : .right)
        y = max(labelBottom, y) + 2
        if let sub { text(sub, font: PDFCanvas.font(8.5), color: .secondaryLabel); y += 1 }
    }

    func rule(color: UIColor = .separator, lineWidth: CGFloat = 0.5) {
        ensure(8)
        let p = UIBezierPath()
        p.move(to: CGPoint(x: margin, y: y + 2))
        p.addLine(to: CGPoint(x: margin + width, y: y + 2))
        color.setStroke(); p.lineWidth = lineWidth; p.stroke()
        y += 6
    }

    /// The brand stripe at the top of a page.
    func bar() {
        PDFCanvas.brand.setFill()
        UIRectFill(CGRect(x: margin, y: y, width: width, height: 4))
        y += 14
    }
}
