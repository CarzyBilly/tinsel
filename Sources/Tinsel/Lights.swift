import AppKit
import CoreGraphics

// MARK: - String lights

enum Lights {
    /// The wire path for a string of lights, in panel coordinates.
    static func polyline(for d: Decoration, in bounds: CGRect) -> [CGPoint] {
        if d.hang == "free" {
            return d.props.map { CGPoint(x: $0.u, y: $0.v) }
        }
        let r = d.displayRect(in: bounds)
        switch d.hang {
        case "around":
            let inset: CGFloat = 7
            let rr = r.insetBy(dx: -inset, dy: -inset)
            var pts: [CGPoint] = []
            let steps = 8
            for i in 0...steps {
                pts.append(CGPoint(x: rr.minX + rr.width * CGFloat(i) / CGFloat(steps), y: rr.maxY))
            }
            for i in 1...steps {
                pts.append(CGPoint(x: rr.maxX, y: rr.maxY - rr.height * CGFloat(i) / CGFloat(steps)))
            }
            for i in 1...steps {
                pts.append(CGPoint(x: rr.maxX - rr.width * CGFloat(i) / CGFloat(steps), y: rr.minY))
            }
            for i in 1...steps {
                pts.append(CGPoint(x: rr.minX, y: rr.minY + rr.height * CGFloat(i) / CGFloat(steps)))
            }
            return pts
        default: // "top"
            var pts: [CGPoint] = []
            let sag: CGFloat = min(16, r.width * 0.04)
            let steps = max(6, Int(r.width / 40))
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = r.minX + r.width * t
                let y = r.maxY + 14 - sin(t * .pi) * sag
                pts.append(CGPoint(x: x, y: y))
            }
            return pts
        }
    }

    static func draw(_ ctx: CGContext, d: Decoration, config: LightConfig, time: Double,
                     in bounds: CGRect) {
        let pts = polyline(for: d, in: bounds)
        guard pts.count > 1 else { return }

        // Wire
        let wire = CGMutablePath()
        wire.move(to: pts[0])
        for p in pts.dropFirst() { wire.addLine(to: p) }
        Art.stroke(ctx, wire, NSColor(white: 0.12, alpha: 0.55), 1.6)

        // Bulbs evenly spaced along the wire
        let spacing: CGFloat = config.density == .packed ? 15 : 26
        var lengths: [CGFloat] = [0]
        var total: CGFloat = 0
        for i in 1..<pts.count {
            total += hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)
            lengths.append(total)
        }
        guard total > 1 else { return }
        let count = max(2, Int(total / spacing))
        let palette = config.style.palette
        let radius: CGFloat = config.style == .mini ? 2.6 : (config.style == .bigRetro ? 5.2 : 3.9)
        let beat = time * (0.5 + config.speed * 3.0)

        for i in 0..<count {
            let want = total * CGFloat(i) / CGFloat(count - 1)
            var idx = 1
            while idx < lengths.count - 1 && lengths[idx] < want { idx += 1 }
            let p0 = pts[max(0, idx - 1)]
            let p1 = pts[min(pts.count - 1, idx)]
            let segStart = lengths[max(0, idx - 1)]
            let segEnd = lengths[min(lengths.count - 1, idx)]
            let t = segEnd > segStart ? max(0, min(1, (want - segStart) / (segEnd - segStart))) : 0
            let p = CGPoint(x: p0.x + (p1.x - p0.x) * t, y: p0.y + (p1.y - p0.y) * t)

            let color: NSColor
            if config.colorIndex >= 0 && config.colorIndex < palette.count {
                color = palette[config.colorIndex]
            } else {
                color = palette[i % palette.count]
            }
            let brightness = level(index: i, of: count, style: config.twinkle, beat: beat)
            ctx.setFillColor(color.withAlphaComponent(0.16 * brightness).cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - radius * 3, y: p.y - radius * 3,
                                       width: radius * 6, height: radius * 6))
            ctx.setFillColor(color.withAlphaComponent(0.35 + 0.65 * brightness).cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - radius, y: p.y - radius,
                                       width: radius * 2, height: radius * 2))
            if config.style == .warmWhite || config.style == .icyBlue {
                ctx.setFillColor(NSColor(white: 1, alpha: 0.55 * brightness).cgColor)
                ctx.fillEllipse(in: CGRect(x: p.x - radius * 0.4, y: p.y - radius * 0.4,
                                           width: radius * 0.8, height: radius * 0.8))
            }
        }
    }

    /// 0 … 1 brightness for the bulb at `index`.
    static func level(index: Int, of count: Int, style: TwinkleStyle, beat: Double) -> Double {
        let phase = Double(index) / Double(max(1, count))
        switch style {
        case .steady:
            return 1
        case .alternate:
            return Int(beat) % 2 == 0 ? (index % 2 == 0 ? 1 : 0.35) : (index % 2 == 0 ? 0.35 : 1)
        case .chase:
            let head = (beat * 0.55).truncatingRemainder(dividingBy: 1)
            let d = abs(phase - head)
            return d < 0.08 || d > 0.92 ? 1 : 0.30
        case .wave:
            return 0.55 + 0.45 * sin(beat * 2 + phase * .pi * 4)
        case .slowFade:
            return 0.5 + 0.5 * sin(beat * 0.8)
        case .blink:
            return (beat * 1.6).truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : 0.12
        }
    }
}

// MARK: - Decoration geometry

extension Decoration {
    /// Base size before the user has resized anything.
    var nominalSize: CGSize {
        switch kind {
        case "snowman":
            let h = height > 0 ? height : 170
            return CGSize(width: h * 0.86, height: h)
        case "tree":
            let h = height > 0 ? height : 320
            return CGSize(width: h * 0.86, height: h)
        case "calendar":
            let w = width > 0 ? width : 300
            return CGSize(width: w, height: w * 0.82)
        case "wreath":
            let h = height > 0 ? height : 120
            return CGSize(width: h, height: h)
        case "lights":
            return CGSize(width: width, height: height)
        default: // ornament
            let s = height > 0 ? height : 54
            return CGSize(width: s, height: s)
        }
    }

    /// Where the item lives inside a panel, in panel coordinates (y up).
    func displayRect(in bounds: CGRect) -> CGRect {
        let s = nominalSize
        if kind == "lights" && hang != "free" {
            // Attached strings store their window rect directly.
            return CGRect(x: x, y: y - s.height, width: s.width, height: s.height)
        }
        return CGRect(x: x - s.width / 2, y: y - s.height / 2, width: s.width, height: s.height)
    }

    func contains(_ point: CGPoint, in bounds: CGRect) -> Bool {
        if kind == "lights" {
            let pts = Lights.polyline(for: self, in: bounds)
            for i in 1..<max(1, pts.count) {
                let a = pts[i - 1], b = pts[i]
                if distance(from: point, toSegment: a, b) < 12 { return true }
            }
            return false
        }
        return displayRect(in: bounds).insetBy(dx: -6, dy: -6).contains(point)
    }

    private func distance(from p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let len2 = dx * dx + dy * dy
        guard len2 > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2))
        return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
    }
}

// MARK: - Item catalogue

enum Catalogue {
    static let standing: [String] = ["present", "lantern", "reindeer", "sled", "treeBare"]
    static let hanging: [String] = ["stocking", "holly", "wreath", "candycane", "mistletoe",
                                    "bell", "snowflake", "star", "bow", "gingerbread", "icicle"]
    static let allOrnaments: [String] = ["bauble", "bell", "candycane", "star", "angel", "bow",
                                         "holly", "mistletoe", "sled", "snowflake", "gingerbread",
                                         "lantern", "present", "reindeer", "stocking", "wreath",
                                         "icicle", "treeBare"]

    static func title(_ kind: String) -> String {
        switch kind {
        case "bauble": return "Bauble"
        case "bell": return "Bell"
        case "candycane": return "Candy cane"
        case "star": return "Star"
        case "angel": return "Angel"
        case "bow": return "Bow"
        case "holly": return "Holly"
        case "mistletoe": return "Mistletoe"
        case "sled": return "Sled"
        case "snowflake": return "Snowflake"
        case "gingerbread": return "Gingerbread"
        case "lantern": return "Lantern"
        case "present": return "Present"
        case "reindeer": return "Reindeer"
        case "stocking": return "Stocking"
        case "wreath": return "Wreath"
        case "icicle": return "Icicle"
        case "treeBare": return "Bare tree"
        case "snowman": return "Snowman"
        case "tree": return "Christmas tree"
        case "calendar": return "Countdown calendar"
        case "lights": return "String of lights"
        default: return kind.capitalized
        }
    }

    static func itemCost(_ kind: String) -> String {
        standing.contains(kind) ? "Stands in the snow" : "Hangs wherever you click"
    }
}
