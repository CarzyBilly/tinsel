import AppKit
import CoreGraphics
import CoreText

// MARK: - Vector art
//
// Everything Tinsel puts on screen is drawn here, in unit space: every routine
// receives a unit rect, maps it to the context, and draws inside 0…1 with y up.
// That keeps one drawing correct at every size, from a 24 pt ornament to a
// 5K desktop picture.

enum Art {
    static func unit(_ ctx: CGContext, _ r: CGRect, _ body: () -> Void) {
        ctx.saveGState()
        ctx.translateBy(x: r.minX, y: r.minY)
        ctx.scaleBy(x: r.width, y: r.height)
        body()
        ctx.restoreGState()
    }

    // MARK: primitives

    static func fill(_ ctx: CGContext, _ path: CGPath, _ color: NSColor) {
        ctx.saveGState()
        ctx.setFillColor(color.cgColor)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()
    }

    static func stroke(_ ctx: CGContext, _ path: CGPath, _ color: NSColor, _ width: CGFloat,
                       cap: CGLineCap = .round) {
        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.setLineCap(cap)
        ctx.setLineJoin(.round)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
    }

    static func circle(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ color: NSColor) {
        fill(ctx, CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2),
                         transform: nil), color)
    }

    static func ring(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ w: CGFloat, _ color: NSColor) {
        stroke(ctx, CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2),
                           transform: nil), color, w)
    }

    static func rounded(_ ctx: CGContext, _ r: CGRect, _ radius: CGFloat, _ color: NSColor) {
        fill(ctx, CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius,
                         transform: nil), color)
    }

    static func linearGradient(_ ctx: CGContext, _ r: CGRect, _ colors: [NSColor],
                               _ stops: [CGFloat]? = nil, vertical: Bool = true) {
        guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors.map(\.cgColor) as CFArray,
                                    locations: (stops ?? defaultStops(colors.count))) else { return }
        ctx.saveGState()
        ctx.clip(to: r)
        let start = CGPoint(x: r.minX, y: vertical ? r.minY : r.minY)
        let end = CGPoint(x: vertical ? r.minX : r.maxX, y: vertical ? r.maxY : r.minY)
        ctx.drawLinearGradient(grad, start: start, end: end, options: [])
        ctx.restoreGState()
    }

    static func defaultStops(_ n: Int) -> [CGFloat] {
        guard n > 1 else { return [0] }
        return (0..<n).map { CGFloat($0) / CGFloat(n - 1) }
    }

    static func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int = 5,
                         rotation: CGFloat = -.pi / 2) -> CGPath {
        let p = CGMutablePath()
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = rotation + CGFloat(i) * .pi / CGFloat(points)
            let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }


    /// Draw a centred string with Core Text, which respects the context's
    /// current transform. (AppKit's string drawing does not.)
    static func text(_ ctx: CGContext, _ string: String, center: CGPoint, size: CGFloat,
                     color: NSColor, weight: NSFont.Weight = .bold, mono: Bool = true) {
        let font = mono ? NSFont.monospacedDigitSystemFont(ofSize: max(4, size), weight: weight)
                        : NSFont.systemFont(ofSize: max(4, size), weight: weight)
        let attr = NSAttributedString(string: string, attributes: [
            .font: font, .foregroundColor: color
        ])
        let line = CTLineCreateWithAttributedString(attr)
        let b = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        ctx.saveGState()
        ctx.textMatrix = .identity
        ctx.textPosition = CGPoint(x: center.x - b.width / 2, y: center.y - b.height / 2)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    static func seededRandom(_ seed: UInt64) -> () -> Double {
        var s = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        return {
            s ^= s << 13; s ^= s >> 7; s ^= s << 17
            return Double(s % 100_000) / 100_000.0
        }
    }

    // MARK: - Ornaments

    /// One ornament, drawn to fill a unit box.
    static func ornament(_ ctx: CGContext, _ kind: String, _ box: CGRect,
                         tint: NSColor, seed: UInt64 = 1) {
        unit(ctx, box) {
            let c = CGPoint(x: 0.5, y: 0.5)
            let shade = tint.blended(withFraction: 0.35, of: .black) ?? tint
            let light = tint.blended(withFraction: 0.4, of: .white) ?? tint
            switch kind {
            case "bauble":
                ring(ctx, CGPoint(x: 0.5, y: 0.82), 0.07, 0.03, NSColor(white: 0.78, alpha: 1))
                rounded(ctx, CGRect(x: 0.44, y: 0.80, width: 0.12, height: 0.10), 0.03,
                        NSColor(white: 0.72, alpha: 1))
                circle(ctx, CGPoint(x: 0.5, y: 0.44), 0.36, shade)
                circle(ctx, CGPoint(x: 0.49, y: 0.47), 0.34, tint)
                ctx.saveGState()
                ctx.addEllipse(in: CGRect(x: 0.24, y: 0.44, width: 0.52, height: 0.46))
                ctx.clip()
                circle(ctx, CGPoint(x: 0.63, y: 0.60), 0.13, light.withAlphaComponent(0.55))
                ctx.restoreGState()
                circle(ctx, CGPoint(x: 0.38, y: 0.56), 0.05, .white.withAlphaComponent(0.6))
            case "bell":
                let p = CGMutablePath()
                p.move(to: CGPoint(x: 0.22, y: 0.20))
                p.addCurve(to: CGPoint(x: 0.5, y: 0.88),
                           control1: CGPoint(x: 0.24, y: 0.62), control2: CGPoint(x: 0.32, y: 0.88))
                p.addCurve(to: CGPoint(x: 0.78, y: 0.20),
                           control1: CGPoint(x: 0.68, y: 0.88), control2: CGPoint(x: 0.76, y: 0.62))
                p.addLine(to: CGPoint(x: 0.22, y: 0.20))
                p.closeSubpath()
                fill(ctx, p, NSColor(red: 0.96, green: 0.78, blue: 0.26, alpha: 1))
                circle(ctx, CGPoint(x: 0.5, y: 0.86), 0.055, NSColor(white: 0.65, alpha: 1))
                circle(ctx, CGPoint(x: 0.5, y: 0.16), 0.075,
                       NSColor(red: 0.85, green: 0.63, blue: 0.16, alpha: 1))
                stroke(ctx, CGPath(rect: CGRect(x: 0.26, y: 0.24, width: 0.48, height: 0.05),
                                   transform: nil),
                       NSColor(red: 0.82, green: 0.60, blue: 0.14, alpha: 1), 0.03)
            case "candycane":
                ctx.saveGState()
                ctx.translateBy(x: 0.12, y: 0.06)
                ctx.scaleBy(x: 0.76, y: 0.88)
                let staff = CGMutablePath()
                staff.move(to: CGPoint(x: 0.42, y: 0.02))
                staff.addLine(to: CGPoint(x: 0.42, y: 0.62))
                staff.addCurve(to: CGPoint(x: 0.72, y: 0.86),
                               control1: CGPoint(x: 0.42, y: 0.92),
                               control2: CGPoint(x: 0.72, y: 0.98))
                stroke(ctx, staff, .white, 0.20)
                ctx.saveGState()
                ctx.addPath(staff.copy(strokingWithWidth: 0.20, lineCap: .round,
                                       lineJoin: .round, miterLimit: 4))
                ctx.clip()
                ctx.setFillColor(NSColor(red: 0.86, green: 0.14, blue: 0.18, alpha: 1).cgColor)
                var i = -1.0
                while i < 1.6 {
                    let d = CGMutablePath()
                    let y0 = CGFloat(i)
                    d.move(to: CGPoint(x: 0, y: y0))
                    d.addLine(to: CGPoint(x: 1, y: y0 + 0.34))
                    d.addLine(to: CGPoint(x: 1, y: y0 + 0.52))
                    d.addLine(to: CGPoint(x: 0, y: y0 + 0.18))
                    d.closeSubpath()
                    ctx.addPath(d)
                    ctx.fillPath()
                    i += 0.30
                }
                ctx.restoreGState()
                ctx.restoreGState()
            case "star":
                fill(ctx, starPath(center: c, outer: 0.46, inner: 0.19),
                     NSColor(red: 0.98, green: 0.84, blue: 0.35, alpha: 1))
                fill(ctx, starPath(center: c, outer: 0.26, inner: 0.10),
                     NSColor(red: 1.0, green: 0.94, blue: 0.68, alpha: 0.9))
            case "angel":
                circle(ctx, CGPoint(x: 0.5, y: 0.90), 0.09,
                       NSColor(red: 0.99, green: 0.88, blue: 0.66, alpha: 1))
                ring(ctx, CGPoint(x: 0.5, y: 1.01), 0.10, 0.028,
                     NSColor(red: 0.98, green: 0.84, blue: 0.38, alpha: 1))
                let body = CGMutablePath()
                body.move(to: CGPoint(x: 0.5, y: 0.04))
                body.addCurve(to: CGPoint(x: 0.5, y: 0.80),
                              control1: CGPoint(x: 0.18, y: 0.10),
                              control2: CGPoint(x: 0.30, y: 0.72))
                body.addCurve(to: CGPoint(x: 0.5, y: 0.04),
                              control1: CGPoint(x: 0.70, y: 0.72),
                              control2: CGPoint(x: 0.82, y: 0.10))
                fill(ctx, body, NSColor(red: 0.96, green: 0.96, blue: 0.99, alpha: 1))
                ctx.saveGState()
                ctx.addEllipse(in: CGRect(x: 0.02, y: 0.40, width: 0.42, height: 0.34))
                ctx.addEllipse(in: CGRect(x: 0.56, y: 0.40, width: 0.42, height: 0.34))
                ctx.setFillColor(NSColor(red: 0.86, green: 0.92, blue: 1.0, alpha: 0.85).cgColor)
                ctx.fillPath()
                ctx.restoreGState()
            case "bow":
                let red = NSColor(red: 0.78, green: 0.10, blue: 0.16, alpha: 1)
                let l = CGMutablePath()
                l.move(to: CGPoint(x: 0.46, y: 0.52))
                l.addCurve(to: CGPoint(x: 0.04, y: 0.28),
                           control1: CGPoint(x: 0.26, y: 0.62), control2: CGPoint(x: 0.04, y: 0.56))
                l.addCurve(to: CGPoint(x: 0.46, y: 0.44),
                           control1: CGPoint(x: 0.06, y: 0.10), control2: CGPoint(x: 0.30, y: 0.24))
                l.closeSubpath()
                let rr = CGMutablePath()
                rr.move(to: CGPoint(x: 0.54, y: 0.52))
                rr.addCurve(to: CGPoint(x: 0.96, y: 0.28),
                            control1: CGPoint(x: 0.74, y: 0.62), control2: CGPoint(x: 0.96, y: 0.56))
                rr.addCurve(to: CGPoint(x: 0.54, y: 0.44),
                            control1: CGPoint(x: 0.94, y: 0.10), control2: CGPoint(x: 0.70, y: 0.24))
                rr.closeSubpath()
                fill(ctx, l, red)
                fill(ctx, rr, red)
                circle(ctx, c, 0.10, red.blended(withFraction: 0.2, of: .white) ?? red)
            case "holly":
                let green = NSColor(red: 0.10, green: 0.44, blue: 0.22, alpha: 1)
                for a in [-0.5, 0.0, 0.5] {
                    ctx.saveGState()
                    ctx.translateBy(x: 0.5, y: 0.5)
                    ctx.rotate(by: CGFloat(a))
                    let leaf = CGMutablePath()
                    leaf.move(to: CGPoint(x: 0, y: 0))
                    leaf.addCurve(to: CGPoint(x: 0.0, y: 0.44),
                                  control1: CGPoint(x: -0.22, y: 0.14),
                                  control2: CGPoint(x: -0.16, y: 0.38))
                    leaf.addCurve(to: CGPoint(x: 0, y: 0),
                                  control1: CGPoint(x: 0.16, y: 0.38),
                                  control2: CGPoint(x: 0.22, y: 0.14))
                    fill(ctx, leaf, green)
                    ctx.restoreGState()
                }
                circle(ctx, CGPoint(x: 0.38, y: 0.38), 0.08,
                       NSColor(red: 0.84, green: 0.12, blue: 0.16, alpha: 1))
                circle(ctx, CGPoint(x: 0.60, y: 0.36), 0.08,
                       NSColor(red: 0.72, green: 0.08, blue: 0.12, alpha: 1))
            case "mistletoe":
                let green = NSColor(red: 0.22, green: 0.50, blue: 0.26, alpha: 1)
                for a in [-0.7, -0.2, 0.3, 0.8] {
                    ctx.saveGState()
                    ctx.translateBy(x: 0.5, y: 0.62)
                    ctx.rotate(by: CGFloat(a))
                    ctx.addEllipse(in: CGRect(x: -0.08, y: -0.26, width: 0.16, height: 0.40))
                    ctx.setFillColor(green.cgColor)
                    ctx.fillPath()
                    ctx.restoreGState()
                }
                for p in [CGPoint(x: 0.42, y: 0.34), CGPoint(x: 0.58, y: 0.32),
                          CGPoint(x: 0.50, y: 0.24)] {
                    circle(ctx, p, 0.075, NSColor(white: 0.96, alpha: 1))
                }
            case "sled":
                let wood = NSColor(red: 0.56, green: 0.30, blue: 0.15, alpha: 1)
                let red = NSColor(red: 0.76, green: 0.12, blue: 0.14, alpha: 1)
                rounded(ctx, CGRect(x: 0.16, y: 0.34, width: 0.66, height: 0.16), 0.03, wood)
                rounded(ctx, CGRect(x: 0.20, y: 0.52, width: 0.58, height: 0.10), 0.03, red)
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.20, y: 0.24))
                    p.addLine(to: CGPoint(x: 0.84, y: 0.24))
                    p.addCurve(to: CGPoint(x: 0.94, y: 0.40),
                               control1: CGPoint(x: 0.92, y: 0.24),
                               control2: CGPoint(x: 0.94, y: 0.30))
                    return p
                }(), NSColor(white: 0.72, alpha: 1), 0.05)
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.30, y: 0.34)); p.addLine(to: CGPoint(x: 0.30, y: 0.24))
                    p.move(to: CGPoint(x: 0.70, y: 0.34)); p.addLine(to: CGPoint(x: 0.70, y: 0.24))
                    return p
                }(), wood, 0.035)
            case "snowflake":
                let w = NSColor(red: 0.76, green: 0.90, blue: 1.0, alpha: 0.95)
                for i in 0..<6 {
                    ctx.saveGState()
                    ctx.translateBy(x: 0.5, y: 0.5)
                    ctx.rotate(by: CGFloat(i) * .pi / 3)
                    let p = CGMutablePath()
                    p.move(to: .zero); p.addLine(to: CGPoint(x: 0, y: 0.46))
                    p.move(to: CGPoint(x: 0, y: 0.24)); p.addLine(to: CGPoint(x: -0.12, y: 0.34))
                    p.move(to: CGPoint(x: 0, y: 0.24)); p.addLine(to: CGPoint(x: 0.12, y: 0.34))
                    p.move(to: CGPoint(x: 0, y: 0.10)); p.addLine(to: CGPoint(x: -0.09, y: 0.18))
                    p.move(to: CGPoint(x: 0, y: 0.10)); p.addLine(to: CGPoint(x: 0.09, y: 0.18))
                    stroke(ctx, p, w, 0.045)
                    ctx.restoreGState()
                }
            case "gingerbread":
                let dough = NSColor(red: 0.66, green: 0.38, blue: 0.16, alpha: 1)
                circle(ctx, CGPoint(x: 0.5, y: 0.74), 0.15, dough)
                rounded(ctx, CGRect(x: 0.37, y: 0.34, width: 0.26, height: 0.32), 0.09, dough)
                for (dx, dy) in [(-0.30, 0.52), (0.30, 0.52)] {
                    rounded(ctx, CGRect(x: 0.5 + dx - 0.06, y: dy, width: 0.12, height: 0.22),
                            0.06, dough)
                }
                for (dx, dy) in [(-0.13, 0.10), (0.13, 0.10)] {
                    rounded(ctx, CGRect(x: 0.5 + dx - 0.07, y: dy, width: 0.14, height: 0.26),
                            0.07, dough)
                }
                for p in [CGPoint(x: 0.44, y: 0.78), CGPoint(x: 0.56, y: 0.78),
                          CGPoint(x: 0.50, y: 0.68)] {
                    circle(ctx, p, 0.028, .white)
                }
                rounded(ctx, CGRect(x: 0.44, y: 0.56, width: 0.12, height: 0.05), 0.02,
                        NSColor(red: 0.95, green: 0.36, blue: 0.42, alpha: 1))
            case "lantern":
                let glow = NSColor(red: 1.0, green: 0.85, blue: 0.48, alpha: 1)
                circle(ctx, CGPoint(x: 0.5, y: 0.48), 0.34, glow.withAlphaComponent(0.22))
                rounded(ctx, CGRect(x: 0.30, y: 0.20, width: 0.40, height: 0.48), 0.05, glow)
                stroke(ctx, CGPath(roundedRect: CGRect(x: 0.30, y: 0.20, width: 0.40, height: 0.48),
                                   cornerWidth: 0.05, cornerHeight: 0.05, transform: nil),
                       NSColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1), 0.035)
                rounded(ctx, CGRect(x: 0.34, y: 0.66, width: 0.32, height: 0.10), 0.03,
                        NSColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1))
                rounded(ctx, CGRect(x: 0.34, y: 0.14, width: 0.32, height: 0.09), 0.03,
                        NSColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1))
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.5, y: 0.76)); p.addArc(center: CGPoint(x: 0.5, y: 0.80),
                                                                   radius: 0.12, startAngle: .pi,
                                                                   endAngle: 0, clockwise: true)
                    return p
                }(), NSColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1), 0.03)
            case "present":
                let box = NSColor(red: 0.72, green: 0.12, blue: 0.16, alpha: 1)
                rounded(ctx, CGRect(x: 0.18, y: 0.14, width: 0.64, height: 0.44), 0.03, box)
                rounded(ctx, CGRect(x: 0.12, y: 0.56, width: 0.76, height: 0.16), 0.03,
                        box.blended(withFraction: 0.12, of: .white) ?? box)
                rounded(ctx, CGRect(x: 0.44, y: 0.14, width: 0.12, height: 0.58), 0.02,
                        NSColor(red: 0.97, green: 0.82, blue: 0.32, alpha: 1))
                circle(ctx, CGPoint(x: 0.44, y: 0.80), 0.09,
                       NSColor(red: 0.97, green: 0.82, blue: 0.32, alpha: 1))
                circle(ctx, CGPoint(x: 0.56, y: 0.80), 0.09,
                       NSColor(red: 0.90, green: 0.72, blue: 0.24, alpha: 1))
            case "reindeer":
                let brown = NSColor(red: 0.44, green: 0.27, blue: 0.16, alpha: 1)
                let antler = NSColor(red: 0.62, green: 0.48, blue: 0.32, alpha: 1)
                ctx.saveGState()
                ctx.translateBy(x: 0.22, y: 0.0)
                let p = CGMutablePath()
                p.move(to: CGPoint(x: 0.28, y: 0.42)); p.addLine(to: CGPoint(x: 0.20, y: 0.80))
                p.move(to: CGPoint(x: 0.24, y: 0.68)); p.addLine(to: CGPoint(x: 0.08, y: 0.78))
                p.move(to: CGPoint(x: 0.24, y: 0.60)); p.addLine(to: CGPoint(x: 0.12, y: 0.64))
                p.move(to: CGPoint(x: 0.20, y: 0.80)); p.addLine(to: CGPoint(x: 0.30, y: 0.92))
                stroke(ctx, p, antler, 0.035)
                ctx.restoreGState()
                fill(ctx, CGPath(ellipseIn: CGRect(x: 0.28, y: 0.16, width: 0.44, height: 0.46),
                                 transform: nil), brown)
                fill(ctx, CGPath(ellipseIn: CGRect(x: 0.16, y: 0.30, width: 0.30, height: 0.24),
                                 transform: nil), brown)
                circle(ctx, CGPoint(x: 0.32, y: 0.44), 0.03, .white)
                circle(ctx, CGPoint(x: 0.40, y: 0.26), 0.055,
                       NSColor(red: 0.78, green: 0.14, blue: 0.16, alpha: 1))
            case "stocking":
                let red = NSColor(red: 0.76, green: 0.12, blue: 0.16, alpha: 1)
                let p = CGMutablePath()
                p.move(to: CGPoint(x: 0.28, y: 0.82))
                p.addLine(to: CGPoint(x: 0.66, y: 0.82))
                p.addLine(to: CGPoint(x: 0.66, y: 0.34))
                p.addCurve(to: CGPoint(x: 0.86, y: 0.20),
                           control1: CGPoint(x: 0.66, y: 0.22),
                           control2: CGPoint(x: 0.80, y: 0.24))
                p.addCurve(to: CGPoint(x: 0.34, y: 0.20),
                           control1: CGPoint(x: 0.86, y: 0.02),
                           control2: CGPoint(x: 0.40, y: 0.04))
                p.addLine(to: CGPoint(x: 0.28, y: 0.34))
                p.closeSubpath()
                fill(ctx, p, red)
                rounded(ctx, CGRect(x: 0.24, y: 0.76, width: 0.46, height: 0.14), 0.05,
                        NSColor(white: 0.97, alpha: 1))
                circle(ctx, CGPoint(x: 0.72, y: 0.44), 0.045,
                       NSColor(red: 0.98, green: 0.84, blue: 0.36, alpha: 1))
            case "wreath":
                drawWreath(ctx)
            case "icicle":
                let p = CGMutablePath()
                p.move(to: CGPoint(x: 0.34, y: 0.98))
                p.addLine(to: CGPoint(x: 0.66, y: 0.98))
                p.addLine(to: CGPoint(x: 0.54, y: 0.12))
                p.addLine(to: CGPoint(x: 0.46, y: 0.12))
                p.closeSubpath()
                fill(ctx, p, NSColor(red: 0.82, green: 0.93, blue: 1.0, alpha: 0.9))
                stroke(ctx, p, .white.withAlphaComponent(0.7), 0.012)
            case "treeBare":
                let bark = NSColor(red: 0.40, green: 0.28, blue: 0.20, alpha: 1)
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.5, y: 0.02)); p.addLine(to: CGPoint(x: 0.5, y: 0.72))
                    p.move(to: CGPoint(x: 0.5, y: 0.52)); p.addLine(to: CGPoint(x: 0.24, y: 0.72))
                    p.move(to: CGPoint(x: 0.5, y: 0.44)); p.addLine(to: CGPoint(x: 0.78, y: 0.66))
                    p.move(to: CGPoint(x: 0.5, y: 0.64)); p.addLine(to: CGPoint(x: 0.40, y: 0.86))
                    p.move(to: CGPoint(x: 0.5, y: 0.60)); p.addLine(to: CGPoint(x: 0.64, y: 0.84))
                    return p
                }(), bark, 0.04)
            default:
                circle(ctx, c, 0.32, tint)
            }
            _ = light
        }
    }

    static func drawWreath(_ ctx: CGContext) {
        let green = NSColor(red: 0.10, green: 0.36, blue: 0.20, alpha: 1)
        let dark = NSColor(red: 0.07, green: 0.26, blue: 0.15, alpha: 1)
        ring(ctx, CGPoint(x: 0.5, y: 0.5), 0.40, 0.20, dark)
        var r = seededRandom(7)
        for _ in 0..<26 {
            let a = r() * 2 * .pi
            let rr = 0.30 + r() * 0.20
            let p = CGPoint(x: 0.5 + cos(a) * rr, y: 0.5 + sin(a) * rr)
            ctx.saveGState()
            ctx.translateBy(x: p.x, y: p.y)
            ctx.rotate(by: a)
            ctx.addEllipse(in: CGRect(x: -0.05, y: -0.10, width: 0.10, height: 0.20))
            ctx.setFillColor(green.cgColor)
            ctx.fillPath()
            ctx.restoreGState()
        }
        for i in 0..<7 {
            let a = Double(i) / 7 * 2 * .pi + 0.4
            circle(ctx, CGPoint(x: 0.5 + cos(a) * 0.36, y: 0.5 + sin(a) * 0.36), 0.035,
                   NSColor(red: 0.86, green: 0.16, blue: 0.20, alpha: 1))
        }
        let red = NSColor(red: 0.78, green: 0.10, blue: 0.16, alpha: 1)
        rounded(ctx, CGRect(x: 0.36, y: 0.02, width: 0.28, height: 0.10), 0.03, red)
        circle(ctx, CGPoint(x: 0.40, y: 0.04), 0.06, red)
        circle(ctx, CGPoint(x: 0.60, y: 0.04), 0.06, red)
    }

    // MARK: - Snowman

    static func snowman(_ ctx: CGContext, _ box: CGRect, radii: [Double],
                        props: [Prop], tint: NSColor = .white, showButtons: Bool = true) {
        let rs = radii.isEmpty ? [30.0, 22.0, 16.0] : radii
        let sum = max(1.0, rs.reduce(0, +))
        // Points per radius unit, so the stack fills the box and the balls stay round.
        let scale = box.height * 0.97 / (2 * sum * 0.94)
        var centers: [CGPoint] = []
        var prevRadius: CGFloat = 0
        var baseY = box.minY
        for r in rs {
            let rp = CGFloat(r) * scale
            if prevRadius > 0 { baseY += (prevRadius + rp) * 0.97 }
            centers.append(CGPoint(x: box.midX, y: baseY + rp))
            prevRadius = rp
        }
        let headRadius = CGFloat(rs.last ?? 16) * scale

        // Balls, bottom first, with a cool edge and a soft highlight.
        for (i, c) in centers.enumerated() {
            let rp = CGFloat(rs[i]) * scale
            circle(ctx, CGPoint(x: c.x + rp * 0.05, y: c.y - rp * 0.06), rp,
                   NSColor(white: 0.84, alpha: 1))
            circle(ctx, c, rp, tint)
            ctx.saveGState()
            ctx.addEllipse(in: CGRect(x: c.x - rp, y: c.y - rp, width: rp * 2, height: rp * 2))
            ctx.clip()
            circle(ctx, CGPoint(x: c.x - rp * 0.34, y: c.y + rp * 0.40), rp * 0.34,
                   NSColor(white: 1, alpha: 0.50))
            ctx.restoreGState()
            if showButtons && i < rs.count - 1 {
                for k in 0..<3 {
                    let dy = (CGFloat(k) - 1) * rp * 0.52
                    circle(ctx, CGPoint(x: c.x, y: c.y + dy), max(1.6, rp * 0.10),
                           NSColor(white: 0.14, alpha: 1))
                }
            }
        }

        // Pieces, arms first so they sit behind the rest.
        let ordered = props.sorted { order($0.kind) < order($1.kind) }
        for p in ordered {
            let v = CGFloat(max(-1, min(1.05, p.v)))
            var cy = box.minY + (v + 1) / 2 * box.height
            let u = CGFloat(max(-1.3, min(1.3, p.u)))
            let cx = box.midX + u * box.width * 0.5
            let sc = CGFloat(max(0.2, p.scale))
            var w = headRadius * 2.6 * sc
            var hh = headRadius * 2.2 * sc
            switch p.kind {
            case "coal": w = headRadius * 0.40 * sc; hh = w
            case "carrot": w = headRadius * 1.6 * sc; hh = headRadius * 0.55 * sc
            case "stickArm": w = headRadius * 2.5 * sc; hh = w * 0.72
            case "scarf": w = headRadius * 2.6 * sc; hh = headRadius * 1.15 * sc
            case "topHat": w = headRadius * 2.0 * sc; hh = headRadius * 1.9 * sc
            case "beanie", "santaHat": w = headRadius * 2.4 * sc; hh = headRadius * 2.0 * sc
            case "earmuffs": w = headRadius * 2.6 * sc; hh = headRadius * 1.5 * sc
            case "broom": w = headRadius * 2.8 * sc; hh = headRadius * 2.8 * sc
            case "bucket", "pinecone", "rock": w = headRadius * 1.25 * sc; hh = w
            case "bowTie": w = headRadius * 1.4 * sc; hh = headRadius * 0.8 * sc
            case "mitten": w = headRadius * 1.1 * sc; hh = headRadius * 1.3 * sc
            default: w = headRadius * 1.8 * sc; hh = headRadius * 1.6 * sc
            }
            // Hats ride above the head rather than through it.
            if p.kind == "topHat" || p.kind == "beanie" || p.kind == "santaHat" {
                cy -= hh * 0.10
            }
            if p.kind == "coal" { cy += 0 }
            let rect = CGRect(x: cx - w / 2, y: cy - hh / 2, width: w, height: hh)
            prop(ctx, p.kind, rect,
                 tint: NSColor(hex: p.color ?? "#C71A24") ?? .red, angle: p.angle)
        }
    }

    /// Draw order for snowman pieces: arms behind, hats and faces in front.
    private static func order(_ kind: String) -> Int {
        switch kind {
        case "stickArm", "broom": return 0
        case "scarf", "bowTie", "mitten": return 1
        default: return 2
        }
    }

    /// A single snowman prop (hat, coal, carrot, …) in a unit box.
    static func prop(_ ctx: CGContext, _ kind: String, _ box: CGRect, tint: NSColor,
                     angle: Double = 0) {
        unit(ctx, box) {
            ctx.translateBy(x: 0.5, y: 0.5)
            ctx.rotate(by: CGFloat(angle))
            ctx.translateBy(x: -0.5, y: -0.5)
            let black = NSColor(white: 0.10, alpha: 1)
            switch kind {
            case "topHat":
                rounded(ctx, CGRect(x: 0.12, y: 0.10, width: 0.76, height: 0.16), 0.05, black)
                rounded(ctx, CGRect(x: 0.26, y: 0.22, width: 0.48, height: 0.56), 0.06, black)
                rounded(ctx, CGRect(x: 0.26, y: 0.34, width: 0.48, height: 0.10), 0.03, tint)
            case "beanie":
                let dome = CGMutablePath()
                dome.move(to: CGPoint(x: 0.14, y: 0.24))
                dome.addCurve(to: CGPoint(x: 0.86, y: 0.24),
                              control1: CGPoint(x: 0.16, y: 0.98),
                              control2: CGPoint(x: 0.84, y: 0.98))
                dome.closeSubpath()
                fill(ctx, dome, tint)
                rounded(ctx, CGRect(x: 0.12, y: 0.14, width: 0.76, height: 0.16), 0.06,
                        tint.blended(withFraction: 0.2, of: .white) ?? tint)
                circle(ctx, CGPoint(x: 0.5, y: 0.92), 0.10,
                       tint.blended(withFraction: 0.35, of: .white) ?? tint)
            case "santaHat":
                let cone = CGMutablePath()
                cone.move(to: CGPoint(x: 0.10, y: 0.26))
                cone.addCurve(to: CGPoint(x: 0.80, y: 0.86),
                              control1: CGPoint(x: 0.24, y: 0.90),
                              control2: CGPoint(x: 0.44, y: 0.98))
                cone.addCurve(to: CGPoint(x: 0.90, y: 0.26),
                              control1: CGPoint(x: 0.92, y: 0.60),
                              control2: CGPoint(x: 0.92, y: 0.40))
                cone.closeSubpath()
                fill(ctx, cone, tint)
                rounded(ctx, CGRect(x: 0.08, y: 0.16, width: 0.84, height: 0.16), 0.07, .white)
                circle(ctx, CGPoint(x: 0.80, y: 0.86), 0.11, .white)
            case "earmuffs":
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.16, y: 0.42))
                    p.addCurve(to: CGPoint(x: 0.84, y: 0.42),
                               control1: CGPoint(x: 0.18, y: 1.06),
                               control2: CGPoint(x: 0.82, y: 1.06))
                    return p
                }(), tint, 0.10)
                circle(ctx, CGPoint(x: 0.16, y: 0.40), 0.16, tint)
                circle(ctx, CGPoint(x: 0.84, y: 0.40), 0.16, tint)
            case "scarf":
                rounded(ctx, CGRect(x: 0.06, y: 0.52, width: 0.88, height: 0.20), 0.06, tint)
                rounded(ctx, CGRect(x: 0.62, y: 0.10, width: 0.22, height: 0.48), 0.06, tint)
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.18, y: 0.62)); p.addLine(to: CGPoint(x: 0.62, y: 0.62))
                    return p
                }(), tint.blended(withFraction: 0.4, of: .black) ?? tint, 0.03)
            case "bowTie":
                let l = CGMutablePath()
                l.move(to: CGPoint(x: 0.46, y: 0.5))
                l.addLine(to: CGPoint(x: 0.06, y: 0.76)); l.addLine(to: CGPoint(x: 0.06, y: 0.24))
                l.closeSubpath()
                let r = CGMutablePath()
                r.move(to: CGPoint(x: 0.54, y: 0.5))
                r.addLine(to: CGPoint(x: 0.94, y: 0.76)); r.addLine(to: CGPoint(x: 0.94, y: 0.24))
                r.closeSubpath()
                fill(ctx, l, tint); fill(ctx, r, tint)
                circle(ctx, CGPoint(x: 0.5, y: 0.5), 0.10,
                       tint.blended(withFraction: 0.25, of: .black) ?? tint)
            case "coal":
                circle(ctx, CGPoint(x: 0.5, y: 0.5), 0.42, NSColor(white: 0.12, alpha: 1))
            case "carrot":
                let carrot = CGMutablePath()
                carrot.move(to: CGPoint(x: 0.12, y: 0.44))
                carrot.addLine(to: CGPoint(x: 0.94, y: 0.60))
                carrot.addLine(to: CGPoint(x: 0.20, y: 0.68))
                carrot.closeSubpath()
                fill(ctx, carrot, NSColor(red: 0.96, green: 0.52, blue: 0.10, alpha: 1))
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.20, y: 0.66)); p.addLine(to: CGPoint(x: 0.30, y: 0.74))
                    p.move(to: CGPoint(x: 0.26, y: 0.62)); p.addLine(to: CGPoint(x: 0.36, y: 0.70))
                    return p
                }(), NSColor(red: 0.36, green: 0.56, blue: 0.20, alpha: 1), 0.04)
            case "stickArm":
                let wood = NSColor(red: 0.42, green: 0.28, blue: 0.17, alpha: 1)
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.10, y: 0.30)); p.addLine(to: CGPoint(x: 0.86, y: 0.68))
                    p.move(to: CGPoint(x: 0.62, y: 0.55)); p.addLine(to: CGPoint(x: 0.72, y: 0.82))
                    p.move(to: CGPoint(x: 0.46, y: 0.45)); p.addLine(to: CGPoint(x: 0.40, y: 0.72))
                    return p
                }(), wood, 0.07)
            case "mitten":
                let m = CGMutablePath()
                m.move(to: CGPoint(x: 0.28, y: 0.20))
                m.addLine(to: CGPoint(x: 0.28, y: 0.62))
                m.addCurve(to: CGPoint(x: 0.62, y: 0.86),
                           control1: CGPoint(x: 0.28, y: 0.92),
                           control2: CGPoint(x: 0.52, y: 0.94))
                m.addCurve(to: CGPoint(x: 0.72, y: 0.56),
                           control1: CGPoint(x: 0.74, y: 0.78),
                           control2: CGPoint(x: 0.72, y: 0.66))
                m.addLine(to: CGPoint(x: 0.72, y: 0.20))
                m.closeSubpath()
                fill(ctx, m, tint)
                rounded(ctx, CGRect(x: 0.22, y: 0.10, width: 0.56, height: 0.14), 0.05, .white)
            case "pipe":
                let brown = NSColor(red: 0.36, green: 0.22, blue: 0.14, alpha: 1)
                rounded(ctx, CGRect(x: 0.10, y: 0.28, width: 0.52, height: 0.14), 0.06, brown)
                rounded(ctx, CGRect(x: 0.50, y: 0.28, width: 0.20, height: 0.44), 0.06, brown)
                circle(ctx, CGPoint(x: 0.60, y: 0.74), 0.16,
                       brown.blended(withFraction: 0.2, of: .black) ?? brown)
            case "broom":
                stroke(ctx, {
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: 0.20, y: 0.12)); p.addLine(to: CGPoint(x: 0.74, y: 0.86))
                    return p
                }(), NSColor(red: 0.58, green: 0.42, blue: 0.24, alpha: 1), 0.06)
                let bristle = CGMutablePath()
                bristle.move(to: CGPoint(x: 0.12, y: 0.06))
                bristle.addLine(to: CGPoint(x: 0.44, y: 0.24))
                bristle.addLine(to: CGPoint(x: 0.24, y: 0.36))
                bristle.closeSubpath()
                fill(ctx, bristle, NSColor(red: 0.86, green: 0.68, blue: 0.32, alpha: 1))
            case "bucket":
                let metal = NSColor(red: 0.52, green: 0.62, blue: 0.70, alpha: 1)
                let b = CGMutablePath()
                b.move(to: CGPoint(x: 0.18, y: 0.16)); b.addLine(to: CGPoint(x: 0.82, y: 0.16))
                b.addLine(to: CGPoint(x: 0.72, y: 0.72)); b.addLine(to: CGPoint(x: 0.28, y: 0.72))
                b.closeSubpath()
                fill(ctx, b, metal)
                stroke(ctx, CGPath(ellipseIn: CGRect(x: 0.26, y: 0.64, width: 0.48, height: 0.14),
                                   transform: nil), metal.blended(withFraction: 0.3, of: .black) ?? metal, 0.035)
            case "pinecone":
                let brown = NSColor(red: 0.40, green: 0.26, blue: 0.14, alpha: 1)
                ctx.saveGState()
                ctx.addEllipse(in: CGRect(x: 0.24, y: 0.10, width: 0.52, height: 0.80))
                ctx.clip()
                for row in 0..<5 {
                    for col in 0..<3 {
                        let x = 0.30 + Double(col) * 0.20 + (row.isMultiple(of: 2) ? 0.0 : 0.10)
                        let y = 0.18 + Double(row) * 0.16
                        ctx.addEllipse(in: CGRect(x: x, y: y, width: 0.16, height: 0.14))
                        ctx.setFillColor(brown.blended(withFraction: row.isMultiple(of: 2) ? 0.18 : 0.0,
                                                       of: .white)?.cgColor ?? brown.cgColor)
                        ctx.fillPath()
                    }
                }
                ctx.restoreGState()
            case "rock":
                let g = NSColor(white: 0.52, alpha: 1)
                let p = CGMutablePath()
                p.move(to: CGPoint(x: 0.16, y: 0.30))
                p.addCurve(to: CGPoint(x: 0.84, y: 0.34),
                           control1: CGPoint(x: 0.20, y: 0.94),
                           control2: CGPoint(x: 0.70, y: 0.98))
                p.addCurve(to: CGPoint(x: 0.16, y: 0.30),
                           control1: CGPoint(x: 0.92, y: 0.18),
                           control2: CGPoint(x: 0.30, y: 0.06))
                fill(ctx, p, g)
            default:
                circle(ctx, CGPoint(x: 0.5, y: 0.5), 0.3, tint)
            }
        }
    }

    // MARK: - Tree

    static func tree(_ ctx: CGContext, _ box: CGRect, ornaments: [Prop], seed: UInt64) {
        let bottom = box.minY + box.height * 0.10
        let top = box.minY + box.height * 0.94
        let midX = box.midX
        let trunk = NSColor(red: 0.34, green: 0.22, blue: 0.14, alpha: 1)
        Art.rounded(ctx, CGRect(x: midX - box.width * 0.055, y: box.minY,
                                width: box.width * 0.11, height: box.height * 0.14),
                    2, trunk)
        let green = NSColor(red: 0.08, green: 0.33, blue: 0.19, alpha: 1)
        let green2 = NSColor(red: 0.11, green: 0.42, blue: 0.24, alpha: 1)
        let tiers = 5
        for i in 0..<tiers {
            let t = Double(i) / Double(tiers)
            let half = box.width * 0.46 * CGFloat(1 - t * 0.74)
            let y0 = bottom + (top - bottom) * CGFloat(t) * 0.86
            let y1 = y0 + (top - bottom) * (0.26 - t * 0.06)
            let p = CGMutablePath()
            p.move(to: CGPoint(x: midX - half, y: y0))
            p.addQuadCurve(to: CGPoint(x: midX, y: y1),
                           control: CGPoint(x: midX - half * 0.45, y: y0 + (y1 - y0) * 0.55))
            p.addQuadCurve(to: CGPoint(x: midX + half, y: y0),
                           control: CGPoint(x: midX + half * 0.45, y: y0 + (y1 - y0) * 0.55))
            p.addQuadCurve(to: CGPoint(x: midX - half, y: y0),
                           control: CGPoint(x: midX, y: y0 - (y1 - y0) * 0.22))
            p.closeSubpath()
            Art.fill(ctx, p, i.isMultiple(of: 2) ? green : green2)
            // Snow catching on the upper edge of each tier
            let cap = CGMutablePath()
            cap.move(to: CGPoint(x: midX - half * 0.92, y: y0 + (y1 - y0) * 0.10))
            cap.addQuadCurve(to: CGPoint(x: midX, y: y1),
                             control: CGPoint(x: midX - half * 0.42, y: y0 + (y1 - y0) * 0.60))
            cap.addQuadCurve(to: CGPoint(x: midX + half * 0.92, y: y0 + (y1 - y0) * 0.10),
                             control: CGPoint(x: midX + half * 0.42, y: y0 + (y1 - y0) * 0.60))
            cap.addQuadCurve(to: CGPoint(x: midX + half * 0.70, y: y0 + (y1 - y0) * 0.02),
                             control: CGPoint(x: midX, y: y0 + (y1 - y0) * 0.30))
            cap.addQuadCurve(to: CGPoint(x: midX - half * 0.92, y: y0 + (y1 - y0) * 0.10),
                             control: CGPoint(x: midX - half * 0.70, y: y0 + (y1 - y0) * 0.02))
            cap.closeSubpath()
            Art.fill(ctx, cap, NSColor(white: 1, alpha: 0.14))

        }
        // Ornaments last, so nothing ends up hidden behind a tier.
        for o in ornaments {
            let ot = Double(min(0.94, max(0.02, (o.v + 1) / 2)))
            let oy = bottom + (top - bottom) * CGFloat(ot) * 0.86
            let ohalf = box.width * 0.46 * CGFloat(1 - ot * 0.74) * 0.92
            let ox = midX + CGFloat(max(-1, min(1, o.u))) * ohalf
            let size = box.width * 0.13 * CGFloat(1.12 - ot * 0.34)
            let orect = CGRect(x: ox - size / 2, y: oy - size / 2, width: size, height: size)
            Art.ornament(ctx, o.kind, orect,
                         tint: NSColor(hex: o.color ?? "#C71A24") ?? .red, seed: seed)
        }
    }

    // MARK: - Countdown calendar

    static func calendar(_ ctx: CGContext, _ box: CGRect, opened: Set<Int>, today: Int) {
        let w = box.width, h = box.height
        let board = NSColor(red: 0.50, green: 0.09, blue: 0.11, alpha: 1)
        let boardLight = NSColor(red: 0.61, green: 0.13, blue: 0.15, alpha: 1)
        let gold = NSColor(red: 0.97, green: 0.82, blue: 0.45, alpha: 1)
        Art.rounded(ctx, box, w * 0.04, board)
        Art.rounded(ctx, box.insetBy(dx: w * 0.035, dy: h * 0.035), w * 0.03, boardLight)
        // Holly at the top corners.
        Art.ornament(ctx, "holly", CGRect(x: box.minX + w * 0.04, y: box.maxY - h * 0.13,
                                          width: w * 0.11, height: w * 0.11),
                     tint: NSColor(red: 0.10, green: 0.44, blue: 0.22, alpha: 1))
        Art.ornament(ctx, "holly", CGRect(x: box.maxX - w * 0.15, y: box.maxY - h * 0.13,
                                          width: w * 0.11, height: w * 0.11),
                     tint: NSColor(red: 0.10, green: 0.44, blue: 0.22, alpha: 1))

        let cols = 6, rows = 4
        let gridTop = box.maxY - h * 0.14
        let gridBottom = box.minY + h * 0.06
        let gridHeight = gridTop - gridBottom
        let cellW = w * 0.88 / CGFloat(cols)
        let cellH = gridHeight / CGFloat(rows)
        let fontSize = cellH * 0.40

        for day in 1...24 {
            let i = day - 1
            let col = i % cols, row = i / cols
            let x = box.minX + w * 0.06 + CGFloat(col) * cellW
            let y = gridTop - CGFloat(row + 1) * cellH
            let r = CGRect(x: x + cellW * 0.10, y: y + cellH * 0.12,
                           width: cellW * 0.80, height: cellH * 0.72)
            if opened.contains(day) {
                Art.rounded(ctx, r, r.width * 0.14, gold)
                let burst = Art.starPath(center: CGPoint(x: r.midX, y: r.midY),
                                         outer: r.width * 0.30, inner: r.width * 0.12)
                Art.fill(ctx, burst, NSColor(red: 0.82, green: 0.28, blue: 0.16, alpha: 1))
            } else {
                Art.rounded(ctx, r, r.width * 0.14,
                            NSColor(red: 0.86, green: 0.18, blue: 0.20, alpha: 1))
                Art.stroke(ctx, CGPath(roundedRect: r.insetBy(dx: 1, dy: 1),
                                       cornerWidth: r.width * 0.14,
                                       cornerHeight: r.width * 0.14, transform: nil),
                           gold.withAlphaComponent(0.55), 1)
                Art.text(ctx, "\(day)", center: CGPoint(x: r.midX, y: r.midY),
                         size: fontSize, color: gold)
            }
            if day == today {
                Art.stroke(ctx, CGPath(roundedRect: r.insetBy(dx: -2, dy: -2),
                                       cornerWidth: r.width * 0.18,
                                       cornerHeight: r.width * 0.18, transform: nil),
                           NSColor(red: 1, green: 0.94, blue: 0.62, alpha: 1), 2)
            }
        }
    }
}
