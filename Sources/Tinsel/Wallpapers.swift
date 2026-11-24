import AppKit
import CoreGraphics

// MARK: - Wallpapers

/// A winter scene spec: palette plus which landmarks to draw. Everything is
/// painted procedurally, so the app ships no photographs.
struct SceneSpec {
    var name: String
    var sky: [String]          // hex, bottom → top
    var ground: String
    var moon: Bool = false
    var aurora: Bool = false
    var mountains: Int = 0
    var pines: Int = 0
    var cabin: Bool = false
    var houses: Int = 0
    var lake: Bool = false
    var stars: Int = 90
    var snowfall: Int = 40
    var snowman: Bool = false
    var tree: Bool = false
    var warm: Bool = false
}

enum Scenes {
    static let all: [SceneSpec] = [
        SceneSpec(name: "Blue Hour", sky: ["#122544", "#24406B", "#3E6690"], ground: "#DCE7F2", mountains: 2, pines: 22, stars: 140, snowfall: 60),
        SceneSpec(name: "Forest Cabin", sky: ["#0E1B2C", "#1D3350", "#33506E"], ground: "#E4ECF4", mountains: 1, pines: 26, cabin: true, stars: 120, snowfall: 90),
        SceneSpec(name: "Tree in the Clearing", sky: ["#101E33", "#223B5C", "#466A8E"], ground: "#E8F0F7", mountains: 1, pines: 12, stars: 100, snowfall: 50, tree: true),
        SceneSpec(name: "Skating Pond", sky: ["#0C1C30", "#1B3556", "#2F5578"], ground: "#E6EFF8", pines: 14, lake: true, stars: 90, snowfall: 40),
        SceneSpec(name: "Mountain Dusk", sky: ["#2A1B2E", "#5B3450", "#B4695E"], ground: "#E9E3E6", moon: true, mountains: 3, pines: 10, stars: 60, snowfall: 30),
        SceneSpec(name: "By the Window", sky: ["#0F1D2E", "#1F3448", "#3B5468"], ground: "#DDE7F0", mountains: 0, cabin: true, stars: 70, snowfall: 70),
        SceneSpec(name: "Lamplit Street", sky: ["#0B1622", "#1A2A38", "#2E4653"], ground: "#DDE6EE", houses: 6, stars: 50, snowfall: 80, warm: true),
        SceneSpec(name: "Sleigh by Moonlight", sky: ["#070F1C", "#132640", "#2B4568"], ground: "#E2ECF6", moon: true, mountains: 1, pines: 18, stars: 180, snowfall: 60),
        SceneSpec(name: "Through the Window", sky: ["#16243A", "#2A4260", "#4C6A88"], ground: "#E7EFF7", cabin: true, stars: 60, snowfall: 60, warm: true),
        SceneSpec(name: "Stone Library", sky: ["#1A1A24", "#2C2B3A", "#4A4757"], ground: "#E0DEE6", houses: 4, stars: 40, snowfall: 35, warm: true),
        SceneSpec(name: "City Loft", sky: ["#0D1420", "#1C2536", "#31405A"], ground: "#DDE4ED", houses: 8, stars: 30, snowfall: 55, warm: true),
        SceneSpec(name: "Sleeper Train", sky: ["#08111C", "#152437", "#273B52"], ground: "#E1E9F2", mountains: 2, pines: 20, stars: 120, snowfall: 70),
        SceneSpec(name: "Snow Garden", sky: ["#132434", "#26405A", "#436A82"], ground: "#ECF2F8", pines: 8, stars: 80, snowfall: 45, tree: true),
        SceneSpec(name: "Paris Apartment", sky: ["#171B2A", "#2B3145", "#4B536B"], ground: "#E2E5EE", houses: 5, stars: 45, snowfall: 40, warm: true),
        SceneSpec(name: "Red Square", sky: ["#101826", "#22314A", "#3B4F6B"], ground: "#E3EAF3", houses: 4, stars: 55, snowfall: 50, warm: true),
        SceneSpec(name: "New York", sky: ["#0A1018", "#18202E", "#2A3648"], ground: "#D9E0EA", houses: 10, stars: 25, snowfall: 60, warm: true),
        SceneSpec(name: "Zermatt", sky: ["#0D1B2E", "#1E3854", "#3C5F80"], ground: "#EAF1F8", mountains: 3, pines: 16, stars: 130, snowfall: 65),
        SceneSpec(name: "Prague", sky: ["#101A28", "#22334A", "#3D5570"], ground: "#E3EAF2", houses: 6, stars: 60, snowfall: 45, warm: true),
        SceneSpec(name: "Quebec", sky: ["#0C1724", "#1D3048", "#36506B"], ground: "#E6EDF5", mountains: 1, houses: 5, stars: 75, snowfall: 75, warm: true),
        SceneSpec(name: "Edinburgh", sky: ["#0E1622", "#1F2B3C", "#3A4A5F"], ground: "#DFE6EF", houses: 7, stars: 40, snowfall: 40, warm: true),
        SceneSpec(name: "London", sky: ["#10161F", "#202B39", "#3A4A5C"], ground: "#DDE4EC", houses: 8, lake: true, stars: 35, snowfall: 50, warm: true),
        SceneSpec(name: "Vienna", sky: ["#131A28", "#27313F", "#475465"], ground: "#E1E7EF", houses: 5, stars: 50, snowfall: 45, warm: true),
        SceneSpec(name: "Copenhagen", sky: ["#0B1622", "#1A2C3E", "#33506A"], ground: "#E4EBF3", houses: 4, lake: true, stars: 60, snowfall: 55, warm: true),
        SceneSpec(name: "Kyoto", sky: ["#141C2C", "#2A3A50", "#4C6274"], ground: "#E7EBF1", mountains: 2, pines: 10, stars: 70, snowfall: 50),
        SceneSpec(name: "Banff", sky: ["#08131F", "#16303F", "#2C5B6B"], ground: "#E9F1F7", aurora: true, mountains: 3, pines: 24, lake: true, stars: 150, snowfall: 60),
        SceneSpec(name: "Lapland", sky: ["#050D18", "#0F2135", "#1E3C56"], ground: "#EAF1F8", aurora: true, pines: 20, stars: 220, snowfall: 90),
        SceneSpec(name: "Neuschwanstein", sky: ["#0D1A2A", "#20364F", "#3A5C78"], ground: "#E9F0F7", mountains: 3, pines: 14, cabin: true, stars: 110, snowfall: 55),
        SceneSpec(name: "Venice", sky: ["#101A26", "#22333F", "#3D5462"], ground: "#E2E9F0", houses: 4, lake: true, stars: 50, snowfall: 40, warm: true),
        SceneSpec(name: "Budapest", sky: ["#0F1724", "#1F2D3E", "#364B60"], ground: "#E1E8F0", houses: 7, stars: 45, snowfall: 50, warm: true),
        SceneSpec(name: "Strasbourg", sky: ["#0C1622", "#1D2C3C", "#35505E"], ground: "#E4EBF2", houses: 6, stars: 55, snowfall: 55, warm: true),
        SceneSpec(name: "Stockholm", sky: ["#0A1520", "#1A2C3E", "#31506A"], ground: "#E5EDF5", pines: 12, houses: 5, lake: true, stars: 85, snowfall: 65, warm: true)
    ]

    static func spec(named name: String) -> SceneSpec {
        all.first { $0.name == name } ?? all[0]
    }
}

enum ScenePainter {
    static func paint(_ spec: SceneSpec, size: CGSize, context ctx: CGContext) {
        let w = size.width, h = size.height
        let rect = CGRect(origin: .zero, size: size)
        // Sky
        let colors = spec.sky.compactMap { NSColor(hex: $0) }
        Art.linearGradient(ctx, rect, colors.reversed())
        var rand = Art.seededRandom(UInt64(abs(spec.name.hashValue % 100_000)) &+ 17)

        // Stars
        ctx.saveGState()
        for _ in 0..<spec.stars {
            let x = rand() * w, y = h * (0.35 + rand() * 0.65)
            let r = 0.4 + rand() * 1.4
            ctx.setFillColor(NSColor(white: 1, alpha: 0.15 + rand() * 0.7).cgColor)
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
        }
        ctx.restoreGState()

        // Aurora
        if spec.aurora {
            for band in 0..<3 {
                let path = CGMutablePath()
                let base = h * (0.55 + Double(band) * 0.08)
                path.move(to: CGPoint(x: 0, y: base))
                for i in stride(from: 0.0, through: 1.0, by: 0.05) {
                    let y = base + sin(i * .pi * 2.2 + Double(band)) * h * 0.06
                    path.addLine(to: CGPoint(x: w * CGFloat(i), y: y))
                }
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
                ctx.saveGState()
                ctx.addPath(path)
                ctx.clip()
                Art.linearGradient(ctx, CGRect(x: 0, y: base - h * 0.1, width: w, height: h * 0.4),
                                   [NSColor(red: 0.35, green: 0.95, blue: 0.70, alpha: 0.34),
                                    NSColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 0.06)])
                ctx.restoreGState()
            }
        }

        // Moon
        if spec.moon {
            let c = CGPoint(x: w * 0.74, y: h * 0.80)
            let r = min(w, h) * 0.055
            ctx.setFillColor(NSColor(white: 1, alpha: 0.07).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r * 2.0, y: c.y - r * 2.0,
                                       width: r * 4.0, height: r * 4.0))
            Art.circle(ctx, c, r, NSColor(red: 0.98, green: 0.97, blue: 0.90, alpha: 0.96))
            Art.circle(ctx, CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.2), r * 0.16,
                       NSColor(white: 0.88, alpha: 0.6))
        }

        // Distant mountains
        for layer in 0..<spec.mountains {
            let t = Double(layer) / Double(max(1, spec.mountains))
            let baseY = h * (0.36 + t * 0.12)
            let peak = h * (0.22 + t * 0.10)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -w * 0.1, y: baseY))
            var x = -w * 0.1
            while x < w * 1.1 {
                let step = w * (0.12 + rand() * 0.10)
                x += step
                let top = peak + (rand() - 0.5) * h * 0.10
                path.addLine(to: CGPoint(x: x - step * 0.5, y: top))
                path.addLine(to: CGPoint(x: x, y: baseY - h * 0.02))
            }
            path.addLine(to: CGPoint(x: w * 1.1, y: -10))
            path.addLine(to: CGPoint(x: -w * 0.1, y: -10))
            path.closeSubpath()
            let shade = NSColor(white: 0.14 + CGFloat(layer) * 0.06, alpha: 0.85)
            Art.fill(ctx, path, shade)
        }

        // Lake
        if spec.lake {
            let lake = CGRect(x: 0, y: 0, width: w, height: h * 0.30)
            Art.linearGradient(ctx, lake,
                               [NSColor(red: 0.07, green: 0.13, blue: 0.20, alpha: 1),
                                NSColor(red: 0.12, green: 0.22, blue: 0.32, alpha: 1)])
            ctx.saveGState()
            ctx.setFillColor(NSColor(white: 1, alpha: 0.10).cgColor)
            for _ in 0..<22 {
                let y = rand() * lake.height
                let x = rand() * w
                let len = 20 + rand() * 160
                ctx.fill(CGRect(x: x, y: y, width: len, height: 1.2))
            }
            ctx.restoreGState()
        }

        // Snow ground
        let gPath = CGMutablePath()
        gPath.move(to: CGPoint(x: -10, y: -10))
        let horizon = spec.lake ? h * 0.26 : h * 0.19
        gPath.addLine(to: CGPoint(x: -10, y: horizon))
        var gx = -10.0
        while gx < w + 40 {
            let step = w * 0.08
            gx += step
            gPath.addQuadCurve(to: CGPoint(x: gx, y: horizon + (rand() - 0.5) * h * 0.035),
                               control: CGPoint(x: gx - step / 2, y: horizon + h * 0.02))
        }
        gPath.addLine(to: CGPoint(x: w + 40, y: -10))
        gPath.closeSubpath()
        Art.fill(ctx, gPath, NSColor(hex: spec.ground) ?? .white)
        ctx.saveGState()
        ctx.addPath(gPath); ctx.clip()
        Art.linearGradient(ctx, CGRect(x: 0, y: -10, width: w, height: horizon + 20),
                           [NSColor(white: 0.72, alpha: 0.30), NSColor(white: 1, alpha: 0.0)])
        ctx.restoreGState()

        // Houses
        for i in 0..<spec.houses {
            let n = CGFloat(spec.houses)
            let width = min(150, w / (n + 1.6))
            let x = w * (0.08 + rand() * 0.8)
            let y = horizon - 4
            let height = width * (0.7 + CGFloat(rand()) * 0.5)
            let body = CGRect(x: x - width / 2, y: y, width: width, height: height)
            Art.fill(ctx, CGPath(rect: body, transform: nil),
                     NSColor(white: 0.10 + CGFloat(rand()) * 0.10, alpha: 0.95))
            // Roof
            let roof = CGMutablePath()
            roof.move(to: CGPoint(x: body.minX - 8, y: body.maxY))
            roof.addLine(to: CGPoint(x: body.midX, y: body.maxY + height * 0.34))
            roof.addLine(to: CGPoint(x: body.maxX + 8, y: body.maxY))
            roof.closeSubpath()
            Art.fill(ctx, roof, NSColor(white: 0.92, alpha: 0.95))
            // Windows
            let lit = NSColor(red: 1.0, green: 0.82, blue: 0.46, alpha: 0.95)
            for row in 0..<2 {
                for col in 0..<2 {
                    let ww = width * 0.18
                    let wx = body.minX + width * (0.22 + CGFloat(col) * 0.42)
                    let wy = body.minY + height * (0.22 + CGFloat(row) * 0.34)
                    let on = rand() > 0.25
                    ctx.setFillColor((on ? lit : NSColor(white: 0.25, alpha: 0.8)).cgColor)
                    ctx.fill(CGRect(x: wx, y: wy, width: ww, height: ww * 1.2))
                }
            }
        }

        // Cabin
        if spec.cabin {
            let cw = w * 0.20, ch = h * 0.13
            let body = CGRect(x: w * 0.36, y: horizon - 6, width: cw, height: ch)
            Art.fill(ctx, CGPath(rect: body, transform: nil),
                     NSColor(red: 0.32, green: 0.20, blue: 0.14, alpha: 1))
            let roof = CGMutablePath()
            roof.move(to: CGPoint(x: body.minX - 16, y: body.maxY))
            roof.addLine(to: CGPoint(x: body.midX, y: body.maxY + ch * 0.55))
            roof.addLine(to: CGPoint(x: body.maxX + 16, y: body.maxY))
            roof.closeSubpath()
            Art.fill(ctx, roof, NSColor(red: 0.30, green: 0.17, blue: 0.12, alpha: 1))
            // Snow on the roof
            let cap = CGMutablePath()
            cap.move(to: CGPoint(x: body.minX - 18, y: body.maxY + 2))
            cap.addLine(to: CGPoint(x: body.midX, y: body.maxY + ch * 0.58))
            cap.addLine(to: CGPoint(x: body.maxX + 18, y: body.maxY + 2))
            cap.addLine(to: CGPoint(x: body.maxX + 18, y: body.maxY - 5))
            cap.addLine(to: CGPoint(x: body.midX, y: body.maxY + ch * 0.46))
            cap.addLine(to: CGPoint(x: body.minX - 18, y: body.maxY - 5))
            cap.closeSubpath()
            Art.fill(ctx, cap, NSColor(white: 0.98, alpha: 0.95))
            let lit = NSColor(red: 1.0, green: 0.80, blue: 0.42, alpha: 1)
            let win = CGPath(roundedRect: CGRect(x: body.midX - cw * 0.12,
                                                y: body.minY + ch * 0.25,
                                                width: cw * 0.24, height: ch * 0.36),
                             cornerWidth: 3, cornerHeight: 3, transform: nil)
            ctx.setFillColor(lit.withAlphaComponent(0.30).cgColor)
            ctx.fillEllipse(in: CGRect(x: body.midX - cw * 0.34, y: body.minY + ch * 0.05,
                                       width: cw * 0.68, height: ch * 0.8))
            Art.fill(ctx, win, lit)
            // Chimney smoke
            ctx.setStrokeColor(NSColor(white: 1, alpha: 0.16).cgColor)
            ctx.setLineWidth(max(2, w * 0.004))
            let smoke = CGMutablePath()
            smoke.move(to: CGPoint(x: body.maxX - cw * 0.18, y: body.maxY + ch * 0.5))
            smoke.addCurve(to: CGPoint(x: body.maxX - cw * 0.05, y: body.maxY + ch * 1.7),
                           control1: CGPoint(x: body.maxX - cw * 0.38, y: body.maxY + ch * 0.9),
                           control2: CGPoint(x: body.maxX + cw * 0.06, y: body.maxY + ch * 1.2))
            ctx.addPath(smoke); ctx.strokePath()
        }

        // Pines
        for _ in 0..<spec.pines {
            let x = rand() * w
            let hh = h * (0.10 + rand() * 0.22)
            drawPine(ctx, at: CGPoint(x: x, y: horizon - h * 0.01), height: hh,
                     color: NSColor(red: 0.05, green: 0.16, blue: 0.13, alpha: 0.96), snow: true)
        }

        // Featured snowman or tree
        if spec.snowman {
            let box = CGRect(x: w * 0.12, y: horizon - h * 0.01, width: h * 0.14 * 0.86, height: h * 0.14)
            Art.snowman(ctx, box, radii: [30, 22, 16],
                        props: [Prop(kind: "topHat", u: 0, v: 0.95, scale: 1, angle: 0, color: "#C71A24"),
                                Prop(kind: "scarf", u: 0, v: 0.55, scale: 1, angle: 0, color: "#C71A24"),
                                Prop(kind: "carrot", u: 0.06, v: 0.62, scale: 0.8, angle: 0),
                                Prop(kind: "coal", u: -0.12, v: 0.72, scale: 0.6, angle: 0),
                                Prop(kind: "coal", u: 0.22, v: 0.72, scale: 0.6, angle: 0)])
        }
        if spec.tree {
            let box = CGRect(x: w * 0.66, y: horizon - h * 0.02, width: h * 0.22 * 0.86, height: h * 0.22)
            Art.tree(ctx, box, ornaments: (0..<6).map { i in
                Prop(kind: ["bauble", "bell", "star", "candycane", "bow", "snowflake"][i],
                     u: Double(i % 2 == 0 ? -0.3 : 0.3),
                     v: Double(i) / 3.2 - 0.7, scale: 1, angle: 0, color: "#C71A24")
            }, seed: 42)
        }

        // Falling snow
        ctx.saveGState()
        for _ in 0..<spec.snowfall {
            let x = rand() * w, y = rand() * h
            let r = 0.8 + rand() * 2.6
            ctx.setFillColor(NSColor(white: 1, alpha: 0.25 + rand() * 0.6).cgColor)
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
        }
        ctx.restoreGState()

        // Soft vignette
        let vg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: [NSColor(white: 0, alpha: 0).cgColor,
                                     NSColor(red: 0.02, green: 0.03, blue: 0.06, alpha: 0.42).cgColor] as CFArray,
                            locations: [0, 1])
        if let vg {
            ctx.drawRadialGradient(vg, startCenter: CGPoint(x: w / 2, y: h * 0.6), startRadius: min(w, h) * 0.22,
                                   endCenter: CGPoint(x: w / 2, y: h * 0.6), endRadius: max(w, h) * 0.86,
                                   options: [])
        }
    }

    static func drawPine(_ ctx: CGContext, at base: CGPoint, height: CGFloat, color: NSColor,
                         snow: Bool = false) {
        let w = height * 0.42
        let trunk = CGPath(rect: CGRect(x: base.x - w * 0.06, y: base.y,
                                        width: w * 0.12, height: height * 0.16), transform: nil)
        Art.fill(ctx, trunk, NSColor(red: 0.20, green: 0.13, blue: 0.09, alpha: 1))
        for tier in 0..<4 {
            let t = CGFloat(tier) / 4
            let half = w / 2 * (1 - t * 0.62)
            let y0 = base.y + height * (0.12 + t * 0.62)
            let y1 = y0 + height * 0.30
            let p = CGMutablePath()
            p.move(to: CGPoint(x: base.x - half, y: y0))
            p.addLine(to: CGPoint(x: base.x, y: y1))
            p.addLine(to: CGPoint(x: base.x + half, y: y0))
            p.closeSubpath()
            Art.fill(ctx, p, color)
            if snow {
                let cap = CGMutablePath()
                cap.move(to: CGPoint(x: base.x - half * 0.9, y: y0 + (y1 - y0) * 0.18))
                cap.addLine(to: CGPoint(x: base.x, y: y1))
                cap.addLine(to: CGPoint(x: base.x + half * 0.9, y: y0 + (y1 - y0) * 0.18))
                cap.addLine(to: CGPoint(x: base.x + half * 0.55, y: y0 + (y1 - y0) * 0.06))
                cap.addLine(to: CGPoint(x: base.x - half * 0.55, y: y0 + (y1 - y0) * 0.06))
                cap.closeSubpath()
                Art.fill(ctx, cap, NSColor(white: 1, alpha: 0.22))
            }
        }
    }

    /// Render a wallpaper to an NSImage (2x for retina desktops).
    static func image(_ spec: SceneSpec, pixelSize: CGSize) -> NSImage {
        let image = NSImage(size: NSSize(width: pixelSize.width / 2, height: pixelSize.height / 2))
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.saveGState()
            ctx.scaleBy(x: 0.5, y: 0.5)
            paint(spec, size: pixelSize, context: ctx)
            ctx.restoreGState()
        }
        image.unlockFocus()
        return image
    }
}
