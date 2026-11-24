import AppKit

// MARK: - Demo scene
//
// `--demo` dresses the desktop with one of everything so the overlay can be
// checked end to end (and screenshotted) without clicking around.

@MainActor
enum Demo {
    static func populate(_ store: TinselStore) {
        let screen = NSScreen.screens.first ?? NSScreen.main
        let size = screen?.frame.size ?? CGSize(width: 1440, height: 900)
        let w = Double(size.width), h = Double(size.height)

        var items: [Decoration] = []

        // A snowman on the desktop.
        var snowman = Decoration(kind: "snowman", x: w * 0.16, y: h * 0.30,
                                screen: 0, height: 260, radii: [34, 25, 18],
                                seed: 20_261_224)
        snowman.props = [
            Prop(kind: "stickArm", u: 0.50, v: 0.10, scale: 1.15, angle: -0.22),
            Prop(kind: "stickArm", u: -0.50, v: 0.10, scale: 1.15, angle: 0.22),
            Prop(kind: "coal", u: -0.10, v: 0.64, scale: 0.85, angle: 0),
            Prop(kind: "coal", u: 0.10, v: 0.64, scale: 0.85, angle: 0),
            Prop(kind: "carrot", u: 0.02, v: 0.58, scale: 0.85, angle: 0),
            Prop(kind: "scarf", u: 0, v: 0.30, scale: 1, angle: 0, color: "#C71A24"),
            Prop(kind: "topHat", u: 0, v: 0.94, scale: 1, angle: 0, color: "#C71A24")
        ]
        items.append(snowman)

        // A tree with ornaments.
        var tree = Decoration(kind: "tree", x: w * 0.52, y: h * 0.34, screen: 0,
                              height: 420, seed: 12)
        let kinds = ["bauble", "bell", "candycane", "star", "angel", "bow", "snowflake",
                     "gingerbread", "present", "holly", "sled", "mistletoe"]
        tree.props = kinds.enumerated().map { i, k in
            Prop(kind: k,
                 u: Double((i % 3) - 1) * 0.55 + 0.06,
                 v: 0.82 - Double(i) * 0.145,
                 scale: 1, angle: 0, color: ornamentPalette[i % ornamentPalette.count])
        }
        items.append(tree)

        // The countdown calendar on a wall of its own.
        var calendar = Decoration(kind: "calendar", x: w * 0.80, y: h * 0.42, screen: 0,
                                  height: 260, width: 320, seed: UInt64(Advent.daysSinceEpoch(Date()) % 100_000))
        calendar.props = [1, 2, 3, 5, 8].map { Prop(kind: "door", color: "\($0)") }
        items.append(calendar)

        // A wreath and a few presents.
        items.append(Decoration(kind: "wreath", x: w * 0.05, y: h * 0.72, screen: 0,
                                height: 150, hang: "free", seed: 3))
        for (i, kind) in ["present", "lantern", "reindeer"].enumerated() {
            items.append(Decoration(kind: "ornament", ornament: kind,
                                    x: w * 0.30 + Double(i) * 90, y: h * 0.16,
                                    screen: 0, height: kind == "present" ? 74 : 88,
                                    seed: UInt64(i + 5),
                                    tint: ornamentPalette[i % ornamentPalette.count]))
        }

        // A tacked string of lights across the top of the screen.
        var lights = Decoration(kind: "lights", x: 0, y: 0, screen: 0, hang: "free", seed: 8)
        lights.props = stride(from: 0.0, through: 1.0, by: 0.05).map { t in
            Prop(kind: "bulb", u: w * (0.06 + 0.88 * t),
                 v: h * 0.88 - sin(Double(t) * .pi) * 30)
        }
        items.append(lights)

        store.decorations = items
        store.bumpArt()
    }
}
