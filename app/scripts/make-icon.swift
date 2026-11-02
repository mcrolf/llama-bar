// Render the Llama Bar app icon as a 1024x1024 PNG: a cream llama on an indigo square.
// Usage: swift app/scripts/make-icon.swift <output.png>
// Coordinates are in a 1024-point canvas with the origin at the top left.
import AppKit

let canvasSize = 1024
let square = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185

enum Palette {
    static let skyTop = rgb(0x5B4BC4)
    static let skyBottom = rgb(0x231B5C)
    static let wool = rgb(0xFFF8F0)
    static let neckWool = rgb(0xF3E8DC)
    static let innerEar = rgb(0xF2B8B0)
    static let muzzle = rgb(0xEADFD3)
    static let eye = rgb(0x1E1B2E)
    static let nose = rgb(0x3A3346)
    static let jawShadow = CGColor(srgbRed: 0.24, green: 0.16, blue: 0.10, alpha: 0.22)
}

func rgb(_ hex: Int) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1)
}

/// The llama is symmetric: each left-side shape is mirrored across the canvas center.
func withMirror(_ path: CGPath) -> CGPath {
    var flip = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: CGFloat(canvasSize), ty: 0)
    let both = CGMutablePath()
    both.addPath(path)
    both.addPath(path.copy(using: &flip)!)
    return both
}

func shape(_ build: (CGMutablePath) -> Void) -> CGPath {
    let path = CGMutablePath()
    build(path)
    return path
}

func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2), transform: nil)
}

enum Llama {
    static let ears = withMirror(shape { path in
        path.move(to: CGPoint(x: 446, y: 430))
        path.addCurve(to: CGPoint(x: 416, y: 210), control1: CGPoint(x: 394, y: 366), control2: CGPoint(x: 380, y: 284))
        path.addCurve(to: CGPoint(x: 494, y: 412), control1: CGPoint(x: 450, y: 280), control2: CGPoint(x: 472, y: 350))
        path.closeSubpath()
    })

    static let innerEars = withMirror(shape { path in
        path.move(to: CGPoint(x: 448, y: 404))
        path.addCurve(to: CGPoint(x: 420, y: 250), control1: CGPoint(x: 412, y: 352), control2: CGPoint(x: 402, y: 296))
        path.addCurve(to: CGPoint(x: 472, y: 392), control1: CGPoint(x: 440, y: 296), control2: CGPoint(x: 456, y: 348))
        path.closeSubpath()
    })

    /// Crown, cheeks, and a muzzle that narrows toward the chin.
    static let head = shape { path in
        path.move(to: CGPoint(x: 398, y: 480))
        path.addCurve(to: CGPoint(x: 512, y: 384), control1: CGPoint(x: 398, y: 410), control2: CGPoint(x: 448, y: 384))
        path.addCurve(to: CGPoint(x: 626, y: 480), control1: CGPoint(x: 576, y: 384), control2: CGPoint(x: 626, y: 410))
        path.addLine(to: CGPoint(x: 620, y: 566))
        path.addCurve(to: CGPoint(x: 588, y: 690), control1: CGPoint(x: 614, y: 612), control2: CGPoint(x: 590, y: 640))
        path.addCurve(to: CGPoint(x: 512, y: 756), control1: CGPoint(x: 586, y: 738), control2: CGPoint(x: 556, y: 756))
        path.addCurve(to: CGPoint(x: 436, y: 690), control1: CGPoint(x: 468, y: 756), control2: CGPoint(x: 438, y: 738))
        path.addCurve(to: CGPoint(x: 404, y: 566), control1: CGPoint(x: 434, y: 640), control2: CGPoint(x: 410, y: 612))
        path.closeSubpath()
        for (cx, cy, r) in [(462.0, 398.0, 40.0), (512, 378, 46), (562, 398, 40)] {
            path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }
    }

    /// Runs past the bottom edge; the square clips it.
    static let neck = shape { path in
        path.addLines(between: [
            CGPoint(x: 440, y: 680), CGPoint(x: 584, y: 680), CGPoint(x: 606, y: 1000), CGPoint(x: 418, y: 1000),
        ])
        path.closeSubpath()
    }

    static let eyes = withMirror(ellipse(460, 530, 18, 23))
    static let eyeHighlights = withMirror(ellipse(466, 522, 6, 6))
    static let muzzle = ellipse(512, 684, 66, 56)
    static let nostrils = withMirror(ellipse(492, 668, 8, 6))
    static let mouth = shape { path in
        path.move(to: CGPoint(x: 496, y: 702))
        path.addQuadCurve(to: CGPoint(x: 528, y: 702), control: CGPoint(x: 512, y: 714))
    }
}

func fill(_ context: CGContext, _ path: CGPath, _ color: CGColor) {
    context.addPath(path)
    context.setFillColor(color)
    context.fillPath()
}

func drawSquare(_ context: CGContext, _ outline: CGPath) {
    context.saveGState()
    // Shadow offsets ignore the flipped transform: negative height still points down.
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: CGColor(gray: 0, alpha: 0.4))
    fill(context, outline, Palette.skyBottom)
    context.restoreGState()

    context.saveGState()
    context.addPath(outline)
    context.clip()
    let sky = CGGradient(colorsSpace: nil, colors: [Palette.skyTop, Palette.skyBottom] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(sky, start: CGPoint(x: 0, y: square.minY), end: CGPoint(x: 0, y: square.maxY), options: [])
    context.restoreGState()
}

/// A soft, flattened shadow where the chin meets the neck.
func drawJawShadow(_ context: CGContext) {
    context.saveGState()
    context.addPath(Llama.neck)
    context.clip()
    context.translateBy(x: 512, y: 750)
    context.scaleBy(x: 1, y: 0.45)
    let clear = Palette.jawShadow.copy(alpha: 0)!
    let shadow = CGGradient(colorsSpace: nil, colors: [Palette.jawShadow, clear] as CFArray, locations: [0, 1])!
    context.drawRadialGradient(shadow, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 120, options: [])
    context.restoreGState()
}

func drawLlama(_ context: CGContext, clippedTo outline: CGPath) {
    context.saveGState()
    context.addPath(outline)
    context.clip()

    fill(context, Llama.neck, Palette.neckWool)
    drawJawShadow(context)

    fill(context, Llama.ears, Palette.wool)
    fill(context, Llama.innerEars, Palette.innerEar)
    fill(context, Llama.head, Palette.wool)
    fill(context, Llama.eyes, Palette.eye)
    fill(context, Llama.eyeHighlights, CGColor(gray: 1, alpha: 1))
    fill(context, Llama.muzzle, Palette.muzzle)
    fill(context, Llama.nostrils, Palette.nose)

    context.addPath(Llama.mouth)
    context.setStrokeColor(Palette.nose)
    context.setLineWidth(7)
    context.setLineCap(.round)
    context.strokePath()
    context.restoreGState()
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.png>\n".utf8))
    exit(2)
}

let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: canvasSize, pixelsHigh: canvasSize,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!.cgContext
context.translateBy(x: 0, y: CGFloat(canvasSize))
context.scaleBy(x: 1, y: -1)

let outline = CGPath(roundedRect: square, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
drawSquare(context, outline)
drawLlama(context, clippedTo: outline)

let png = bitmap.representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
