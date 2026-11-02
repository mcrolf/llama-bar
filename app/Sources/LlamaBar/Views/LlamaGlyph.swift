import AppKit

/// The menu bar llama: a side profile (upright ears, long neck, snout forward), which reads as
/// a llama at menu bar size where a front-facing head reads as a donkey. Drawn as a template
/// image so macOS tints it for light and dark menu bars. Coordinates are in a 100-unit square
/// with the origin at the top left; every subpath winds clockwise so overlaps stay filled.
enum LlamaGlyph {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { bounds in
            let scale = bounds.width / 100
            let transform = AffineTransform(scale: scale)
            let silhouette = Self.silhouette
            silhouette.transform(using: transform)
            NSColor.black.setFill()
            silhouette.fill()

            let eye = NSBezierPath(ovalIn: NSRect(x: 56, y: 38, width: 8, height: 8))
            eye.transform(using: transform)
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            eye.fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Llama Bar"
        return image
    }()

    private static var silhouette: NSBezierPath {
        let path = NSBezierPath()
        // Back of the neck, up over the crown, along the nose, then down the throat.
        path.move(to: NSPoint(x: 28, y: 100))
        path.line(to: NSPoint(x: 31, y: 60))
        path.curve(to: NSPoint(x: 36, y: 32), controlPoint1: NSPoint(x: 29, y: 48), controlPoint2: NSPoint(x: 30, y: 38))
        path.curve(to: NSPoint(x: 66, y: 32), controlPoint1: NSPoint(x: 44, y: 26), controlPoint2: NSPoint(x: 56, y: 27))
        path.curve(to: NSPoint(x: 88, y: 46), controlPoint1: NSPoint(x: 75, y: 36), controlPoint2: NSPoint(x: 85, y: 39))
        path.curve(to: NSPoint(x: 78, y: 58), controlPoint1: NSPoint(x: 91, y: 52), controlPoint2: NSPoint(x: 86, y: 58))
        path.curve(to: NSPoint(x: 59, y: 64), controlPoint1: NSPoint(x: 70, y: 58), controlPoint2: NSPoint(x: 62, y: 59))
        path.curve(to: NSPoint(x: 60, y: 100), controlPoint1: NSPoint(x: 64, y: 76), controlPoint2: NSPoint(x: 64, y: 88))
        path.close()
        // Near ear, then the far ear just behind it.
        path.move(to: NSPoint(x: 36, y: 36))
        path.curve(to: NSPoint(x: 44, y: 2), controlPoint1: NSPoint(x: 30, y: 24), controlPoint2: NSPoint(x: 33, y: 8))
        path.curve(to: NSPoint(x: 48, y: 30), controlPoint1: NSPoint(x: 46, y: 12), controlPoint2: NSPoint(x: 46, y: 22))
        path.close()
        path.move(to: NSPoint(x: 30, y: 42))
        path.curve(to: NSPoint(x: 30, y: 6), controlPoint1: NSPoint(x: 23, y: 30), controlPoint2: NSPoint(x: 22, y: 14))
        path.curve(to: NSPoint(x: 38, y: 33), controlPoint1: NSPoint(x: 35, y: 14), controlPoint2: NSPoint(x: 37, y: 24))
        path.close()
        return path
    }
}
