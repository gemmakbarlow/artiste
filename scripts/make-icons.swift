// Generates AppIcon.png and LaunchGlyph.png. Run: swift scripts/make-icons.swift
import AppKit

let green = NSColor(srgbRed: 0x2D / 255, green: 0xB8 / 255, blue: 0x4C / 255, alpha: 1)

func symbol(_ name: String, height: CGFloat, color: NSColor = .white) -> NSImage {
    let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)!
    let config = NSImage.SymbolConfiguration(pointSize: 600, weight: .regular)
        .applying(.init(paletteColors: [color]))
    let img = base.withSymbolConfiguration(config)!
    let scale = height / img.size.height
    let out = NSImage(size: NSSize(width: img.size.width * scale, height: height))
    out.lockFocus()
    img.draw(in: NSRect(origin: .zero, size: out.size))
    out.unlockFocus()
    return out
}

func render(size: Int, opaque: Bool, to path: String, draw: (CGFloat) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    if opaque { green.setFill(); NSRect(x: 0, y: 0, width: size, height: size).fill() }
    draw(CGFloat(size))
    NSGraphicsContext.restoreGraphicsState()
    var data = rep.representation(using: .png, properties: [:])!
    if opaque {
        // Re-encode without an alpha channel (App Store icons must be opaque).
        let cg = rep.cgImage!
        let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: size, height: size))
        let flat = NSBitmapImageRep(cgImage: ctx.makeImage()!)
        data = flat.representation(using: .png, properties: [:])!
    }
    try! data.write(to: URL(fileURLWithPath: path))
}

/// Drop with the brush across its lower right. `outline` adds a green knockout
/// copy under the brush (needed on the opaque icon only).
func drawGlyph(in s: CGFloat, outline: Bool) {
    let drop = symbol("drop.fill", height: s * 0.70)
    drop.draw(in: NSRect(x: (s - drop.size.width) / 2, y: (s - drop.size.height) / 2,
                         width: drop.size.width, height: drop.size.height))
    let cx = s * 0.66, cy = s * 0.30
    var brushes = [symbol("paintbrush.pointed.fill", height: s * 0.45)]
    if outline { brushes.insert(symbol("paintbrush.pointed.fill", height: s * 0.45 * 1.16, color: green), at: 0) }
    for img in brushes {
        img.draw(in: NSRect(x: cx - img.size.width / 2, y: cy - img.size.height / 2,
                            width: img.size.width, height: img.size.height))
    }
}

let root = "Artiste/Resources/Assets.xcassets"
render(size: 1024, opaque: true, to: "\(root)/AppIcon.appiconset/AppIcon.png") { drawGlyph(in: $0, outline: true) }
render(size: 400, opaque: false, to: "\(root)/LaunchGlyph.imageset/LaunchGlyph.png") { drawGlyph(in: $0, outline: false) }
