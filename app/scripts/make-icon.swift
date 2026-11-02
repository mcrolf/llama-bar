// Render the Llama Bar app icon as a 1024x1024 PNG.
// Usage: swift app/scripts/make-icon.swift <output.png>
import AppKit

let canvasSize = 1024
let squareSize: CGFloat = 824
let cornerRadius: CGFloat = 185
let symbolFraction: CGFloat = 0.55

func makeBitmap() -> NSBitmapImageRep {
    NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: canvasSize, pixelsHigh: canvasSize,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
}

func drawSquare(_ square: NSRect) {
    let path = NSBezierPath(roundedRect: square, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor.black.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.24, green: 0.28, blue: 0.35, alpha: 1),
        ending: NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.07, alpha: 1))!
    gradient.draw(in: path, angle: -90)
}

func drawSymbol(centeredIn square: NSRect) {
    let configuration = NSImage.SymbolConfiguration(pointSize: 400, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    let symbol = NSImage(systemSymbolName: "cube.fill", accessibilityDescription: nil)
        ?? NSImage(systemSymbolName: "cube", accessibilityDescription: nil)
    guard let image = symbol?.withSymbolConfiguration(configuration) else {
        FileHandle.standardError.write(Data("cube symbol unavailable\n".utf8))
        exit(1)
    }

    let target = square.width * symbolFraction
    let scale = target / max(image.size.width, image.size.height)
    let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
    let origin = NSPoint(x: square.midX - size.width / 2, y: square.midY - size.height / 2)
    image.draw(in: NSRect(origin: origin, size: size))
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.png>\n".utf8))
    exit(2)
}

let bitmap = makeBitmap()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let margin = (CGFloat(canvasSize) - squareSize) / 2
let square = NSRect(x: margin, y: margin, width: squareSize, height: squareSize)
drawSquare(square)
drawSymbol(centeredIn: square)
NSGraphicsContext.current?.flushGraphics()

let png = bitmap.representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
