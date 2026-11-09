import AppKit

let size = 1024
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
                                 hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 32),
      let ctx = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("no bitmap") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = ctx
let full = NSRect(x: 0, y: 0, width: size, height: size)

// Brand teal, lighter at the top. The system rounds the corners, so the artwork is a full square.
NSGradient(colors: [NSColor(srgbRed: 0.13, green: 0.60, blue: 0.55, alpha: 1), NSColor(srgbRed: 0.04, green: 0.34, blue: 0.32, alpha: 1)])!
    .draw(in: full, angle: -90)

// A soft light from the top-left corner.
NSGradient(colors: [NSColor.white.withAlphaComponent(0.20), NSColor.white.withAlphaComponent(0)])!
    .draw(fromCenter: NSPoint(x: 220, y: 900), radius: 0, toCenter: NSPoint(x: 220, y: 900), radius: 760, options: [])

// The house.
let config = NSImage.SymbolConfiguration(pointSize: 560, weight: .bold)
guard let base = NSImage(systemSymbolName: "house.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) else { fatalError("no symbol") }
let tinted = NSImage(size: base.size, flipped: false) { rect in
    base.draw(in: rect)
    NSColor.white.set()
    rect.fill(using: .sourceAtop)
    return true
}
let w = tinted.size.width, h = tinted.size.height
let house = NSRect(x: (CGFloat(size) - w) / 2, y: (CGFloat(size) - h) / 2 - 10, width: w, height: h)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
shadow.shadowBlurRadius = 36
shadow.shadowOffset = NSSize(width: 0, height: -14)
NSGraphicsContext.saveGraphicsState()
shadow.set()
tinted.draw(in: house)
NSGraphicsContext.restoreGraphicsState()

// A gold check badge on the corner of the house: rent collected.
let gold = NSColor(srgbRed: 0.93, green: 0.68, blue: 0.13, alpha: 1)
let bx: CGFloat = 770, by: CGFloat = 250, br: CGFloat = 138
let shadow2 = NSShadow()
shadow2.shadowColor = NSColor.black.withAlphaComponent(0.30)
shadow2.shadowBlurRadius = 28
shadow2.shadowOffset = NSSize(width: 0, height: -10)
NSGraphicsContext.saveGraphicsState()
shadow2.set()
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(x: bx - br - 16, y: by - br - 16, width: (br + 16) * 2, height: (br + 16) * 2)).fill()
NSGraphicsContext.restoreGraphicsState()
gold.setFill()
NSBezierPath(ovalIn: NSRect(x: bx - br, y: by - br, width: br * 2, height: br * 2)).fill()
let tick = NSBezierPath()
tick.move(to: NSPoint(x: bx - 66, y: by - 2))
tick.line(to: NSPoint(x: bx - 16, y: by - 54))
tick.line(to: NSPoint(x: bx + 72, y: by + 56))
tick.lineWidth = 40; tick.lineCapStyle = .round; tick.lineJoinStyle = .round
NSColor.white.setStroke(); tick.stroke()

NSGraphicsContext.restoreGraphicsState()
let out = CommandLine.arguments[1]
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote", out, rep.pixelsWide, "x", rep.pixelsHigh)
