import AppKit
import CoreGraphics

// MARK: - Snow simulation

/// A snow field: falling flakes, a drifting pile at the bottom, icicles on the
/// things above it. One scene per overlay window; the back and front overlays
/// run their own scene so the two layers never look identical.
final class SnowScene {
    struct Flake {
        var x: Double
        var y: Double
        var vy: Double
        var vx: Double
        var r: Double
        var alpha: Double
        var phase: Double
        var spin: Double
    }

    var flakes: [Flake] = []
    var pile: [Double] = []
    var size: CGSize = .zero
    var settings = SnowSettings()
    /// 1 = front layer, 0.45 = the quiet layer behind windows.
    var intensity: Double = 1
    var pilingEnabled = true
    var seed: UInt64 = 1

    private var t: Double = 0
    private var rand: () -> Double
    private var pileTarget: Double = 0

    init(seed: UInt64) {
        self.seed = seed
        var s = seed == 0 ? 0x2545F4914F6CDD1D : seed
        self.rand = {
            s ^= s << 13; s ^= s >> 7; s ^= s << 17
            return Double(s % 1_000_000) / 1_000_000.0
        }
    }

    var flakesWanted: Int {
        let area = Double(size.width * size.height)
        guard area > 0 else { return 0 }
        let perPoint = settings.amount.rate * intensity
        let count = area / 9500.0 * perPoint
        return Int(min(1100, max(0, count)))
    }

    func configure(size: CGSize, settings: SnowSettings, intensity: Double, piling: Bool) {
        let resized = size != self.size
        self.size = size
        self.settings = settings
        self.intensity = intensity
        self.pilingEnabled = piling
        let cols = max(8, Int(size.width / 5))
        if pile.count != cols {
            pile = Array(repeating: 0, count: cols)
        }
        if resized || flakes.count > flakesWanted + 40 || flakes.count < flakesWanted - 40 {
            rebuild()
        }
    }

    func rebuild() {
        flakes.removeAll(keepingCapacity: true)
        let want = flakesWanted
        guard size.width > 1, size.height > 1 else { return }
        for _ in 0..<want {
            flakes.append(newFlake(anywhere: true))
        }
    }

    private func newFlake(anywhere: Bool) -> Flake {
        let range = settings.flakeSize.range
        let r = range.lowerBound + rand() * (range.upperBound - range.lowerBound)
        let depth = 0.55 + rand() * 0.65
        let y = anywhere ? rand() * Double(size.height) : Double(size.height) + r * 4
        let vy = 18.0 + r * 7.0 + rand() * 12.0
        return Flake(x: rand() * Double(size.width), y: y, vy: vy * settings.pace.factor * depth,
                     vx: 0, r: r * depth, alpha: 0.35 + rand() * 0.55,
                     phase: rand() * .pi * 2, spin: (rand() - 0.5) * 0.8)
    }

    private func pileHeight(at x: Double) -> Double {
        guard !pile.isEmpty else { return 0 }
        let f = min(max(x / Double(size.width), 0), 0.9999) * Double(pile.count - 1)
        let i = Int(f)
        let frac = f - Double(i)
        let a = pile[i]
        let b = pile[min(i + 1, pile.count - 1)]
        return a * (1 - frac) + b * frac
    }

    private func addToPile(at x: Double, amount: Double) {
        guard !pile.isEmpty else { return }
        let i = min(pile.count - 1, max(0, Int(x / Double(size.width) * Double(pile.count))))
        pile[i] = min(maxPile, pile[i] + amount)
        if i > 0 { pile[i - 1] = min(maxPile, pile[i - 1] + amount * 0.45) }
        if i < pile.count - 1 { pile[i + 1] = min(maxPile, pile[i + 1] + amount * 0.45) }
    }

    var maxPile: Double {
        let base = settings.depth == .deep ? 0.20 : 0.09
        return Double(size.height) * base * intensity
    }

    func clearPile() {
        pile = Array(repeating: 0, count: pile.count)
    }

    func melt(_ dt: Double) {
        for i in pile.indices { pile[i] = max(0, pile[i] - dt * 9) }
    }

    func step(_ dt: Double) {
        t += dt
        let gust = settings.wind.strength * (0.55 + 0.45 * sin(t * 0.55))
        let flakeRange = settings.flakeSize.range

        for i in flakes.indices {
            var f = flakes[i]
            let wobble = sin(t * 1.3 + f.phase) * 9 + cos(t * 0.6 + f.phase * 1.7) * 5
            f.x += (gust + wobble) * dt
            f.y -= f.vy * dt
            f.phase += f.spin * dt
            let ground = pileHeight(at: f.x)
            if f.y <= ground {
                if pilingEnabled && settings.piling && intensity > 0.6 {
                    addToPile(at: f.x, amount: f.r * 0.09)
                }
                f = newFlake(anywhere: false)
            }
            if f.x < -20 { f.x = Double(size.width) + 10 }
            if f.x > Double(size.width) + 20 { f.x = -10 }
            flakes[i] = f
        }

        // Pile settles: smooth and slightly shrink.
        if pile.count > 1 {
            var newPile = pile
            for i in pile.indices {
                let l = pile[max(0, i - 1)]
                let r = pile[min(pile.count - 1, i + 1)]
                newPile[i] = pile[i] * 0.94 + (l + r) * 0.03
            }
            pile = newPile
        }

        // Keep the flake count in step with the settings.
        if flakes.count < flakesWanted {
            for _ in 0..<min(24, flakesWanted - flakes.count) { flakes.append(newFlake(anywhere: true)) }
        } else if flakes.count > flakesWanted + 60 {
            flakes.removeLast(flakes.count - flakesWanted)
        }
        _ = flakeRange
    }

    // MARK: drawing

    func draw(in ctx: CGContext, bounds: CGRect, icicles: [(x: Double, top: Double, seed: UInt64)]) {
        guard size.width > 0 else { return }
        let flakeColor = NSColor(white: 1.0, alpha: 1)

        // Ground pile.
        if settings.piling && pile.contains(where: { $0 > 0.4 }) {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            for (i, h) in pile.enumerated() {
                let x = CGFloat(i) / CGFloat(max(1, pile.count - 1)) * bounds.width
                path.addLine(to: CGPoint(x: x, y: CGFloat(h)))
            }
            path.addLine(to: CGPoint(x: bounds.width, y: 0))
            path.closeSubpath()
            ctx.saveGState()
            ctx.addPath(path)
            ctx.clip()
            Art.linearGradient(ctx, bounds, [NSColor(white: 1, alpha: 0.95),
                                             NSColor(white: 0.94, alpha: 0.85)])
            ctx.restoreGState()
        }

        // Icicles hanging from whatever we were told about.
        if settings.ice {
            for ic in icicles {
                var r = Art.seededRandom(ic.seed)
                var x = ic.x
                let top = bounds.height - CGFloat(ic.top)
                while x < ic.x + 260 {
                    let len = 6 + r() * 26
                    let w = 3 + r() * 6
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: x - w / 2, y: top))
                    p.addLine(to: CGPoint(x: x + w / 2, y: top))
                    p.addLine(to: CGPoint(x: x + 0.6, y: top - len))
                    p.addLine(to: CGPoint(x: x - 0.6, y: top - len))
                    p.closeSubpath()
                    Art.fill(ctx, p, NSColor(red: 0.82, green: 0.93, blue: 1.0, alpha: 0.75))
                    x += w + 5 + r() * 22
                }
            }
        }

        // Flakes, back to front for a soft depth cue.
        ctx.saveGState()
        ctx.setFillColor(flakeColor.cgColor)
        for f in flakes {
            let a = f.alpha * (0.35 + 0.65 * min(1, f.r / 2.6))
            let r = CGFloat(f.r)
            ctx.setFillColor(NSColor(white: 1, alpha: a * 0.30).cgColor)
            ctx.fillEllipse(in: CGRect(x: CGFloat(f.x) - r * 1.4, y: CGFloat(f.y) - r * 1.4,
                                       width: r * 2.8, height: r * 2.8))
            ctx.setFillColor(NSColor(white: 1, alpha: a).cgColor)
            ctx.fillEllipse(in: CGRect(x: CGFloat(f.x) - r, y: CGFloat(f.y) - r,
                                       width: r * 2, height: r * 2))
        }
        ctx.restoreGState()
    }

    /// Snow caps sitting on top of other windows, drawn in panel coordinates.
    func drawCaps(in ctx: CGContext, rects: [CGRect]) {
        guard settings.piling else { return }
        for r in rects where r.width > 30 {
            let path = CGMutablePath()
            let h = min(9.0, max(4.0, r.height * 0.012))
            path.move(to: CGPoint(x: r.minX - 6, y: r.maxY - h))
            path.addQuadCurve(to: CGPoint(x: r.maxX + 6, y: r.maxY - h),
                              control: CGPoint(x: r.midX, y: r.maxY + h * 1.4))
            path.addLine(to: CGPoint(x: r.maxX + 6, y: r.maxY - h * 2.2))
            path.addQuadCurve(to: CGPoint(x: r.minX - 6, y: r.maxY - h * 2.2),
                              control: CGPoint(x: r.midX, y: r.maxY))
            path.closeSubpath()
            Art.fill(ctx, path, NSColor(white: 1, alpha: 0.92))
        }
    }
}
