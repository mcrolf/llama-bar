// Render the Llama Bar app icon as a 1024x1024 PNG: a tipsy low-poly llama in one purple hue.
// Usage: swift app/scripts/make-icon.swift <output.png>
// Coordinates are in a 1024-point canvas with the origin at the top left. Mesh vertices carry a
// depth (z) used only for shading: each facet is lit from the upper left.
import AppKit

let hue: CGFloat = 256.0 / 360
func tone(_ lightness: CGFloat, _ saturation: CGFloat = 0.7, _ alpha: CGFloat = 1) -> CGColor {
    // HSL to RGB with a fixed hue.
    let c = (1 - abs(2 * lightness - 1)) * saturation
    let h = hue * 6, x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1)), m = lightness - c / 2
    let (r, g, b): (CGFloat, CGFloat, CGFloat) =
        h < 1 ? (c, x, 0) : h < 2 ? (x, c, 0) : h < 3 ? (0, c, x) : h < 4 ? (0, x, c) : h < 5 ? (x, 0, c) : (c, 0, x)
    return CGColor(srgbRed: r + m, green: g + m, blue: b + m, alpha: alpha)
}

struct V { var x, y, z: CGFloat; var mirrored: V { V(x: 1024 - x, y: y, z: z) }; var p: CGPoint { CGPoint(x: x, y: y) } }
typealias Tri = (V, V, V)

/// Lambert shade from a light up and to the left, mapped onto a lightness range.
func shade(_ t: Tri, light lo: CGFloat, _ hi: CGFloat) -> CGColor {
    let (a, b, c) = t
    let u = (b.x - a.x, b.y - a.y, b.z - a.z), w = (c.x - a.x, c.y - a.y, c.z - a.z)
    var n = (u.1 * w.2 - u.2 * w.1, u.2 * w.0 - u.0 * w.2, u.0 * w.1 - u.1 * w.0)
    if n.2 < 0 { n = (-n.0, -n.1, -n.2) }
    let len = sqrt(n.0 * n.0 + n.1 * n.1 + n.2 * n.2)
    let l = (-0.45, -0.55, 0.70), ll = sqrt(0.45 * 0.45 + 0.55 * 0.55 + 0.7 * 0.7)
    let d = max(0, (n.0 * l.0 + n.1 * l.1 + n.2 * l.2) / (len * ll))
    return tone(lo + (hi - lo) * d, 0.75)
}

func poly(_ pts: [CGPoint]) -> CGPath { let p = CGMutablePath(); p.addLines(between: pts); p.closeSubpath(); return p }
func paint(_ c: CGContext, _ path: CGPath, _ color: CGColor) {
    // Stroke in the fill color too, so neighboring facets leave no hairline seams.
    c.addPath(path); c.setFillColor(color); c.fillPath()
    c.addPath(path); c.setStrokeColor(color); c.setLineWidth(1.5); c.setLineJoin(.round); c.strokePath()
}
func facets(_ c: CGContext, _ tris: [Tri], _ lo: CGFloat, _ hi: CGFloat) {
    for t in tris { paint(c, poly([t.0.p, t.1.p, t.2.p]), shade(t, light: lo, hi)) }
}
func withMirror(_ tris: [Tri]) -> [Tri] { tris + tris.map { ($0.0.mirrored, $0.1.mirrored, $0.2.mirrored) } }
func mirrorPoints(_ pts: [CGPoint]) -> [CGPoint] { pts.map { CGPoint(x: 1024 - $0.x, y: $0.y) } }

// Head mesh: center line C, left side L (mirrored for the right).
let C = [V(x: 512, y: 372, z: 40), V(x: 512, y: 450, z: 70), V(x: 512, y: 540, z: 80), V(x: 512, y: 620, z: 95),
         V(x: 512, y: 668, z: 112), V(x: 512, y: 714, z: 92), V(x: 512, y: 760, z: 55), V(x: 512, y: 334, z: 30)]
let L = [V(x: 450, y: 392, z: 22), V(x: 402, y: 462, z: 0), V(x: 458, y: 498, z: 58), V(x: 404, y: 570, z: 0),
         V(x: 462, y: 584, z: 58), V(x: 428, y: 652, z: 8), V(x: 466, y: 662, z: 74), V(x: 450, y: 716, z: 30),
         V(x: 482, y: 750, z: 28), V(x: 474, y: 350, z: 26)]
let head = withMirror([
    (L[9], C[7], C[0]), (L[0], L[9], C[0]), (C[0], L[0], C[1]), (L[0], L[1], L[2]), (L[0], L[2], C[1]),
    (C[1], L[2], C[2]), (L[1], L[3], L[2]), (L[2], L[3], L[4]), (L[2], L[4], C[2]), (C[2], L[4], C[3]),
    (L[3], L[5], L[4]), (L[4], L[5], L[6]), (L[4], L[6], C[3]), (C[3], L[6], C[4]), (L[5], L[7], L[6]),
    (C[4], L[6], C[5]), (L[6], L[7], C[5]), (L[7], L[8], C[5]), (L[8], C[6], C[5]),
])

let upEar: [Tri] = {
    let e = [V(x: 446, y: 428, z: 10), V(x: 494, y: 410, z: 10), V(x: 418, y: 204, z: 0),
             V(x: 398, y: 322, z: 0), V(x: 452, y: 330, z: 34), V(x: 476, y: 300, z: 0)]
    return [(e[0], e[3], e[4]), (e[3], e[2], e[4]), (e[4], e[2], e[5]), (e[4], e[5], e[1]), (e[0], e[4], e[1])]
}()
let flopEar: [Tri] = {
    let f = [V(x: 562, y: 404, z: 10), V(x: 606, y: 462, z: 10), V(x: 774, y: 478, z: 0),
             V(x: 680, y: 394, z: 0), V(x: 668, y: 442, z: 34), V(x: 690, y: 502, z: 0)]
    return [(f[0], f[3], f[4]), (f[3], f[2], f[4]), (f[4], f[2], f[5]), (f[4], f[5], f[1]), (f[0], f[4], f[1])]
}()
let neck: [Tri] = {
    let t = [V(x: 446, y: 690, z: 0), V(x: 512, y: 690, z: 40), V(x: 578, y: 690, z: 0)]
    let m = [V(x: 430, y: 850, z: 0), V(x: 512, y: 850, z: 46), V(x: 594, y: 850, z: 0)]
    let b = [V(x: 412, y: 1010, z: 0), V(x: 512, y: 1010, z: 52), V(x: 612, y: 1010, z: 0)]
    var tris: [Tri] = []
    for (u, d) in [(t, m), (m, b)] {
        tris += [(u[0], d[0], d[1]), (u[0], d[1], u[1]), (u[1], d[1], d[2]), (u[1], d[2], u[2])]
    }
    return tris
}()

func hexagon(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
    poly((0..<6).map { i in
        let a = CGFloat(i) * .pi / 3 + .pi / 6
        return CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
    })
}

/// Half-closed eye whose heavy lid droops toward the outer corner.
func eye(outer: CGPoint, inner: CGPoint, depth: CGFloat) -> [CGPoint] {
    let mid = CGPoint(x: (outer.x + inner.x) / 2, y: (outer.y + inner.y) / 2)
    return [outer, inner, CGPoint(x: inner.x - 6, y: inner.y + depth * 0.7),
            CGPoint(x: mid.x, y: mid.y + depth), CGPoint(x: outer.x + 8, y: outer.y + depth * 0.6)]
}

func draw(_ c: CGContext) {
    let square = CGRect(x: 100, y: 100, width: 824, height: 824)
    let outline = CGPath(roundedRect: square, cornerWidth: 185, cornerHeight: 185, transform: nil)
    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: tone(0.08, 0.6, 0.45))
    c.addPath(outline); c.setFillColor(tone(0.24)); c.fillPath()
    c.restoreGState()

    c.saveGState(); c.addPath(outline); c.clip()
    let sky = CGGradient(colorsSpace: nil, colors: [tone(0.50, 0.62), tone(0.22, 0.62)] as CFArray, locations: [0, 1])!
    c.drawLinearGradient(sky, start: CGPoint(x: 0, y: 100), end: CGPoint(x: 0, y: 924), options: [])

    for (x, y, r) in [(318.0, 362.0, 30.0), (262, 270, 20), (232, 198, 12)] as [(CGFloat, CGFloat, CGFloat)] {
        paint(c, hexagon(x, y, r), tone(0.9, 0.7, 0.16))
        c.addPath(hexagon(x, y, r)); c.setStrokeColor(tone(0.9, 0.7, 0.9)); c.setLineWidth(max(5, r * 0.3))
        c.setLineJoin(.miter); c.strokePath()
    }
    facets(c, neck, 0.66, 0.84)

    c.saveGState()
    c.translateBy(x: 512, y: 700); c.rotate(by: 16 * .pi / 180); c.translateBy(x: -512, y: -700)
    facets(c, upEar, 0.64, 0.95)
    paint(c, poly([CGPoint(x: 440, y: 404), CGPoint(x: 422, y: 262), CGPoint(x: 470, y: 394)]), tone(0.62, 0.75))
    facets(c, flopEar, 0.64, 0.95)
    paint(c, poly([CGPoint(x: 598, y: 424), CGPoint(x: 738, y: 472), CGPoint(x: 616, y: 450)]), tone(0.62, 0.75))
    facets(c, head, 0.66, 0.97)

    let ink = tone(0.16, 0.65)
    paint(c, poly(eye(outer: CGPoint(x: 430, y: 538), inner: CGPoint(x: 490, y: 524), depth: 20)), ink)
    paint(c, poly(mirrorPoints(eye(outer: CGPoint(x: 430, y: 546), inner: CGPoint(x: 490, y: 530), depth: 14))), ink)
    paint(c, poly([CGPoint(x: 484, y: 662), CGPoint(x: 500, y: 664), CGPoint(x: 494, y: 674)]), ink)
    paint(c, poly(mirrorPoints([CGPoint(x: 484, y: 662), CGPoint(x: 500, y: 664), CGPoint(x: 494, y: 674)])), ink)
    // Tongue hanging out the right side, then a lopsided grin over it.
    paint(c, poly([CGPoint(x: 520, y: 708), CGPoint(x: 546, y: 702), CGPoint(x: 548, y: 728), CGPoint(x: 534, y: 742)]), tone(0.60, 0.75))
    paint(c, poly([CGPoint(x: 520, y: 708), CGPoint(x: 534, y: 742), CGPoint(x: 524, y: 730)]), tone(0.52, 0.75))
    paint(c, poly([CGPoint(x: 484, y: 700), CGPoint(x: 512, y: 716), CGPoint(x: 548, y: 698),
                   CGPoint(x: 548, y: 705), CGPoint(x: 512, y: 724), CGPoint(x: 482, y: 707)]), ink)
    c.restoreGState()
    c.restoreGState()
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.png>\n".utf8))
    exit(2)
}

let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.translateBy(x: 0, y: 1024)
context.scaleBy(x: 1, y: -1)
draw(context)
let png = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
