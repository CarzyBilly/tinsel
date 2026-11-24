import AppKit
import CoreGraphics

// MARK: - Offscreen rendering and self-checks
//
// Used by the build script and by `--selftest`: everything the app draws can
// be rendered without a window so regressions are visible in CI.

enum Diagnostics {
    @discardableResult
    static func run() -> Bool {
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--render-samples"), i + 1 < args.count {
            renderSamples(into: args[i + 1])
            print("wrote samples to \(args[i + 1])")
            return true
        }
        if let i = args.firstIndex(of: "--render-icon"), i + 1 < args.count {
            renderIcon(to: args[i + 1])
            print("wrote icon to \(args[i + 1])")
            return true
        }
        if args.contains("--selftest") {
            exit(selftest() ? 0 : 1)
        }
        return false
    }

    static func canvas(_ size: CGSize, _ draw: (CGContext) -> Void) -> NSImage {
        let image = NSImage(size: NSSize(width: size.width, height: size.height))
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            draw(ctx)
        }
        image.unlockFocus()
        return image
    }

    static func write(_ image: NSImage, to url: URL) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
    }

    static func label(_ text: String, at point: CGPoint, size: CGFloat = 10) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: .medium),
            .foregroundColor: NSColor(white: 0.92, alpha: 1)
        ]
        NSAttributedString(string: text, attributes: attrs).draw(at: point)
    }

    // MARK: samples

    static func renderSamples(into dir: String) {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let base = URL(fileURLWithPath: dir)

        // Ornaments sheet
        let cell = CGSize(width: 120, height: 140)
        let kinds = Catalogue.allOrnaments
        let sheet = canvas(CGSize(width: cell.width * 6, height: cell.height * 3)) { ctx in
            ctx.setFillColor(NSColor(white: 0.10, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: cell.width * 6, height: cell.height * 3))
            for (i, kind) in kinds.enumerated() {
                let col = i % 6, row = i / 6
                let origin = CGPoint(x: CGFloat(col) * cell.width,
                                     y: cell.height * 3 - CGFloat(row + 1) * cell.height)
                let box = CGRect(x: origin.x + 18, y: origin.y + 34, width: 84, height: 84)
                Art.ornament(ctx, kind, box,
                             tint: NSColor(red: 0.85, green: 0.20, blue: 0.24, alpha: 1),
                             seed: UInt64(i + 1))
                label(Catalogue.title(kind), at: CGPoint(x: origin.x + 16, y: origin.y + 12))
            }
        }
        write(sheet, to: base.appendingPathComponent("ornaments.png"))

        // Snowman pieces
        let props = ["topHat", "beanie", "santaHat", "earmuffs", "scarf", "mitten", "bowTie",
                     "coal", "carrot", "pipe", "stickArm", "broom", "bucket", "pinecone", "rock"]
        let propSheet = canvas(CGSize(width: 120 * 5, height: 140 * 3)) { ctx in
            ctx.setFillColor(NSColor(white: 0.10, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 420))
            for (i, kind) in props.enumerated() {
                let col = i % 5, row = i / 5
                let origin = CGPoint(x: CGFloat(col) * 120, y: 420 - CGFloat(row + 1) * 140)
                Art.prop(ctx, kind, CGRect(x: origin.x + 22, y: origin.y + 40, width: 76, height: 76),
                         tint: NSColor(red: 0.85, green: 0.20, blue: 0.24, alpha: 1))
                label(snowmanPieceTitle(kind), at: CGPoint(x: origin.x + 18, y: origin.y + 14))
            }
        }
        write(propSheet, to: base.appendingPathComponent("snowman-pieces.png"))

        // Composite snowman
        let snowman = canvas(CGSize(width: 420, height: 520)) { ctx in
            Art.linearGradient(ctx, CGRect(x: 0, y: 0, width: 420, height: 520),
                               [NSColor(hex: "#16283F")!, NSColor(hex: "#3A5F86")!])
            Art.snowman(ctx, CGRect(x: 90, y: 40, width: 250, height: 430),
                        radii: [34, 25, 18],
                        props: [Prop(kind: "stickArm", u: 0.50, v: 0.10, scale: 1.15, angle: -0.22),
                                Prop(kind: "stickArm", u: -0.50, v: 0.10, scale: 1.15, angle: 0.22),
                                Prop(kind: "coal", u: -0.10, v: 0.64, scale: 0.85, angle: 0),
                                Prop(kind: "coal", u: 0.10, v: 0.64, scale: 0.85, angle: 0),
                                Prop(kind: "carrot", u: 0.02, v: 0.58, scale: 0.85, angle: 0),
                                Prop(kind: "scarf", u: 0, v: 0.30, scale: 1, angle: 0, color: "#C71A24"),
                                Prop(kind: "topHat", u: 0, v: 0.94, scale: 1, angle: 0, color: "#C71A24")])
        }
        write(snowman, to: base.appendingPathComponent("snowman.png"))

        // Tree with ornaments
        let tree = canvas(CGSize(width: 480, height: 560)) { ctx in
            Art.linearGradient(ctx, CGRect(x: 0, y: 0, width: 480, height: 560),
                               [NSColor(hex: "#101B2A")!, NSColor(hex: "#2D4A63")!])
            let ornaments = ["bauble", "bell", "candycane", "star", "angel", "bow",
                             "snowflake", "gingerbread", "holly", "present"].enumerated().map { i, k in
                Prop(kind: k, u: Double(i % 2 == 0 ? -0.55 : 0.5),
                     v: 0.85 - Double(i) * 0.19, scale: 1, angle: 0, color: "#C71A24")
            }
            Art.tree(ctx, CGRect(x: 90, y: 30, width: 300, height: 500),
                     ornaments: ornaments, seed: 12)
        }
        write(tree, to: base.appendingPathComponent("tree.png"))

        // Calendar
        let calendar = canvas(CGSize(width: 420, height: 340)) { ctx in
            ctx.setFillColor(NSColor(hex: "#12202F")!.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 420, height: 340))
            Art.calendar(ctx, CGRect(x: 20, y: 20, width: 380, height: 300),
                         opened: [1, 2, 3, 6, 8, 11], today: 12)
        }
        write(calendar, to: base.appendingPathComponent("calendar.png"))

        // Lights
        let lights = canvas(CGSize(width: 560, height: 200)) { ctx in
            ctx.setFillColor(NSColor(hex: "#141220")!.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 560, height: 200))
            for (i, style) in LightStyle.allCases.enumerated() {
                var cfg = LightConfig()
                cfg.style = style
                cfg.twinkle = .steady
                let y = 170 - Double(i) * 28
                let d = Decoration(kind: "lights", x: 0, y: 0, hang: "free",
                                   props: stride(from: 0.0, through: 1.0, by: 0.05).map { t in
                                       Prop(kind: "bulb", u: 90 + 440 * t,
                                            v: y - sin(t * .pi) * 14)
                                   })
                Lights.draw(ctx, d: d, config: cfg, time: 0.35, in: CGRect(x: 0, y: 0, width: 560, height: 200))
                label(style.title, at: CGPoint(x: 6, y: y - 3), size: 8)
            }
        }
        write(lights, to: base.appendingPathComponent("lights.png"))

        // Wallpaper contact sheet
        let thumb = CGSize(width: 240, height: 150)
        let cols = 4
        let rows = Int(ceil(Double(Scenes.all.count) / Double(cols)))
        let sheet2 = canvas(CGSize(width: thumb.width * CGFloat(cols),
                                   height: thumb.height * CGFloat(rows))) { ctx in
            for (i, spec) in Scenes.all.enumerated() {
                let col = i % cols, row = i / cols
                let rect = CGRect(x: CGFloat(col) * thumb.width,
                                  y: CGFloat(rows - row - 1) * thumb.height,
                                  width: thumb.width - 6, height: thumb.height - 6)
                ctx.saveGState()
                ctx.translateBy(x: rect.minX, y: rect.minY)
                ScenePainter.paint(spec, size: rect.size, context: ctx)
                ctx.restoreGState()
            }
        }
        write(sheet2, to: base.appendingPathComponent("wallpapers.png"))

        // One full-size wallpaper
        let big = ScenePainter.image(Scenes.all[1], pixelSize: CGSize(width: 1600, height: 1000))
        write(big, to: base.appendingPathComponent("wallpaper-sample.png"))

        // Banners
        for pane in Pane.allCases {
            let size = CGSize(width: 880, height: 208)
            let img = canvas(size) { ctx in
                BannerPainter.paintForDiagnostics(pane, size: size, ctx: ctx)
            }
            write(img, to: base.appendingPathComponent("banner-\(pane.rawValue).png"))
        }
    }

    static func renderIcon(to path: String) {
        let size = CGSize(width: 1024, height: 1024)
        let image = canvas(size) { ctx in
            let rect = CGRect(origin: .zero, size: size)
            ctx.saveGState()
            let rounded = CGPath(roundedRect: rect.insetBy(dx: 40, dy: 40),
                                 cornerWidth: 190, cornerHeight: 190, transform: nil)
            ctx.addPath(rounded)
            ctx.clip()
            Art.linearGradient(ctx, rect, [NSColor(hex: "#0E2036")!, NSColor(hex: "#2C5B86")!])
            // Snow drift
            let drift = CGMutablePath()
            drift.move(to: CGPoint(x: 0, y: 80))
            drift.addCurve(to: CGPoint(x: 1024, y: 130),
                           control1: CGPoint(x: 320, y: 260),
                           control2: CGPoint(x: 700, y: 0))
            drift.addLine(to: CGPoint(x: 1024, y: 0))
            drift.addLine(to: CGPoint(x: 0, y: 0))
            drift.closeSubpath()
            Art.fill(ctx, drift, NSColor(white: 1, alpha: 0.92))
            Art.ornament(ctx, "bauble", CGRect(x: 250, y: 300, width: 420, height: 520),
                         tint: NSColor(red: 0.84, green: 0.16, blue: 0.20, alpha: 1), seed: 3)
            Art.ornament(ctx, "star", CGRect(x: 620, y: 620, width: 240, height: 240),
                         tint: NSColor(red: 0.98, green: 0.84, blue: 0.35, alpha: 1), seed: 5)
            for i in 0..<26 {
                var r = Art.seededRandom(UInt64(i) + 11)
                let x = r() * 1024, y = r() * 1024
                let rr = 3 + r() * 7
                ctx.setFillColor(NSColor(white: 1, alpha: 0.5 + r() * 0.4).cgColor)
                ctx.fillEllipse(in: CGRect(x: x, y: y, width: rr, height: rr))
            }
            ctx.restoreGState()
        }
        write(image, to: URL(fileURLWithPath: path))
    }

    // MARK: self test

    static func selftest() -> Bool {
        var failures: [String] = []
        let defaultSettings = SnowSettings()

        func check(_ name: String, _ condition: Bool) {
            if condition {
                print("ok   \(name)")
            } else {
                failures.append(name)
                print("FAIL \(name)")
            }
        }

        // Art renders something
        let probe = canvas(CGSize(width: 64, height: 64)) { ctx in
            Art.ornament(ctx, "bauble", CGRect(x: 4, y: 4, width: 56, height: 56),
                         tint: .red, seed: 1)
        }
        check("ornament renders", probe.size.width == 64)

        // Geometry: an ornament is centred on its point
        var d = Decoration(kind: "ornament", ornament: "bauble", x: 400, y: 300, height: 60)
        let bounds = CGRect(x: 0, y: 0, width: 1200, height: 800)
        let r = d.displayRect(in: bounds)
        check("ornament centred", abs(r.midX - 400) < 0.5 && abs(r.midY - 300) < 0.5)
        check("ornament hit test", d.contains(CGPoint(x: 400, y: 300), in: bounds))
        check("ornament misses", !d.contains(CGPoint(x: 900, y: 300), in: bounds))

        // Snowman height tracks its balls
        d = Decoration(kind: "snowman", x: 500, y: 300, height: 210, radii: [30, 22, 16])
        check("snowman has size", d.displayRect(in: bounds).height == 210)

        // Lights levels stay in range
        for style in TwinkleStyle.allCases {
            let values = (0..<20).map { Lights.level(index: $0, of: 20, style: style, beat: 1.3) }
            check("lights \(style.rawValue) in range", values.allSatisfy { $0 >= 0 && $0 <= 1 })
        }

        // Advent rules
        check("advent unlocked within 1…24",
              (1...24).contains(Advent.unlocked(Decoration(kind: "calendar", seed: 100))))
        check("sleeps till christmas sane", Advent.sleepsTillChristmas >= 0 && Advent.sleepsTillChristmas <= 366)

        // Wallpaper renders at the asked size
        let spec = Scenes.all[0]
        let img = ScenePainter.image(spec, pixelSize: CGSize(width: 800, height: 500))
        check("wallpaper renders", img.size.width == 400 && img.size.height == 250)
        check("wallpaper catalogue", Scenes.all.count >= 24)
        check("wallpaper names unique", Set(Scenes.all.map(\.name)).count == Scenes.all.count)

        // Persistence round trip
        let snap = TinselStore.Snapshot(settings: SnowSettings(), decorations: [d], looks: [],
                                        snowing: true, decorationsShown: true)
        if let data = try? JSONEncoder().encode(snap),
           let back = try? JSONDecoder().decode(TinselStore.Snapshot.self, from: data) {
            check("state round trip", back.decorations.count == 1 && back.decorations[0].kind == "snowman")
        } else {
            check("state round trip", false)
        }

        // Every pane banner and every wallpaper must draw without trapping.
        for pane in Pane.allCases {
            let img = canvas(CGSize(width: 880, height: 208)) { ctx in
                BannerPainter.paintForDiagnostics(pane, size: CGSize(width: 880, height: 208), ctx: ctx)
            }
            check("banner renders: \(pane.title)", img.size.width == 880)
        }
        for spec in Scenes.all {
            let img = canvas(CGSize(width: 320, height: 200)) { ctx in
                ScenePainter.paint(spec, size: CGSize(width: 320, height: 200), context: ctx)
            }
            check("scene renders: \(spec.name)", img.size.width == 320)
        }

        // Settings defaults are coherent
        let s = defaultSettings
        check("default layering", s.layering == .behindEverything)
        check("saver off by default", s.saverAfter == .off)

        // Store behaviour, on a throwaway suite so the user's decorations survive.
        MainActor.assumeIsolated {
            let suite = UserDefaults(suiteName: "com.carzybilly.tinsel.tests") ?? .standard
            suite.removePersistentDomain(forName: "com.carzybilly.tinsel.tests")
            let store = TinselStore(defaults: suite)
            store.decorations = []
            store.looks = []

            let ball = Decoration(kind: "snowman", x: 100, y: 100, height: 160, radii: [30, 22])
            store.add(ball)
            check("store adds decoration", store.decorations.count == 1)

            var grown = ball
            grown.radii = [30, 22, 15]
            store.update(grown)
            check("store updates decoration", store.decorations.first?.radii.count == 3)

            store.saveLook(named: "Christmas Eve")
            check("look saved", store.looks.count == 1 && store.looks[0].items.count == 1)
            store.removeAll()
            check("everything taken down", store.decorations.isEmpty)
            store.applyLook(store.looks[0])
            check("look puts it back", store.decorations.count == 1)
            store.deleteLook(store.looks[0])
            check("look deleted", store.looks.isEmpty)

            var calendar = Decoration(kind: "calendar", x: 10, y: 10, seed: 42)
            store.add(calendar)
            calendar = store.decorations.first!
            store.markDoor(4, on: calendar)
            check("advent door remembered",
                  store.openedDoors(for: store.decorations.first!).contains(4))
            store.markDoor(4, on: store.decorations.first!)
            check("advent door not duplicated",
                  store.decorations.first!.props.filter { $0.kind == "door" }.count == 1)

            let lights = Decoration(kind: "lights", x: 200, y: 700, hang: "free", props: [
                Prop(kind: "bulb", u: 100, v: 700), Prop(kind: "bulb", u: 300, v: 690)
            ])
            let path = Lights.polyline(for: lights, in: CGRect(x: 0, y: 0, width: 1200, height: 800))
            check("free light string keeps its points", path.count == 2)
            let attached = Decoration(kind: "lights", x: 600, y: 500, height: 200, width: 300, hang: "top")
            let attachedPath = Lights.polyline(for: attached,
                                              in: CGRect(x: 0, y: 0, width: 1200, height: 800))
            check("window light string spans the window", attachedPath.count > 4)
            check("light string hit test",
                  attached.contains(CGPoint(x: 600, y: 514), in: CGRect(x: 0, y: 0, width: 1200, height: 800)))

            store.removeAll()
            store.flush()
            suite.removePersistentDomain(forName: "com.carzybilly.tinsel.tests")
        }

        print("")
        if failures.isEmpty {
            print("selftest: all checks passed")
            return true
        }
        print("selftest: \(failures.count) failed: \(failures.joined(separator: ", "))")
        return false
    }
}
