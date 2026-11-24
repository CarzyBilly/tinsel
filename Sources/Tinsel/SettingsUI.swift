import AppKit
import SwiftUI

// MARK: - Pane list

enum Pane: String, CaseIterable, Identifiable {
    case snowfall, piling, screensaver, lights, snowmen, tree, decorations, countdown, saved, wallpapers
    var id: String { rawValue }

    var title: String {
        switch self {
        case .snowfall: return "Snowfall"
        case .piling: return "Piling Up"
        case .screensaver: return "Screen Saver"
        case .lights: return "Christmas Lights"
        case .snowmen: return "Snowmen"
        case .tree: return "Christmas Tree"
        case .decorations: return "Decorations"
        case .countdown: return "Countdown Calendar"
        case .saved: return "My Decorations"
        case .wallpapers: return "Wallpapers"
        }
    }

    var subtitle: String {
        switch self {
        case .snowfall: return "How much falls, where it falls, the flakes and the wind."
        case .piling: return "How it builds up, where it settles, and shaking it off."
        case .screensaver: return "Snow that starts on its own while you're away."
        case .lights: return "String lights along windows, around them, or anywhere."
        case .snowmen: return "Build a snowman, as tall as you like, and dress it up."
        case .tree: return "Put up a tree and hang ornaments wherever you like."
        case .decorations: return "Presents, lanterns, reindeer, stockings and more."
        case .countdown: return "A door to open every day, with a surprise behind it."
        case .saved: return "Put everything away and bring it back, or save a look."
        case .wallpapers: return "Christmas desktop pictures to go with the snow."
        }
    }

    var symbol: String {
        switch self {
        case .snowfall: return "cloud.snow.fill"
        case .piling: return "mountain.2.fill"
        case .screensaver: return "moon.stars.fill"
        case .lights: return "lightbulb.fill"
        case .snowmen: return "snowman"
        case .tree: return "tree.fill"
        case .decorations: return "gift.fill"
        case .countdown: return "calendar"
        case .saved: return "archivebox.fill"
        case .wallpapers: return "photo.fill"
        }
    }

    var tint: Color {
        switch self {
        case .snowfall: return Color(red: 0.30, green: 0.63, blue: 0.92)
        case .piling: return Color(red: 0.42, green: 0.56, blue: 0.70)
        case .screensaver: return Color(red: 0.44, green: 0.40, blue: 0.86)
        case .lights: return Color(red: 0.96, green: 0.68, blue: 0.16)
        case .snowmen: return Color(red: 0.32, green: 0.66, blue: 0.94)
        case .tree: return Color(red: 0.18, green: 0.56, blue: 0.32)
        case .decorations: return Color(red: 0.86, green: 0.24, blue: 0.30)
        case .countdown: return Color(red: 0.88, green: 0.26, blue: 0.36)
        case .saved: return Color(red: 0.52, green: 0.46, blue: 0.86)
        case .wallpapers: return Color(red: 0.24, green: 0.52, blue: 0.86)
        }
    }

    static let groups: [(String, [Pane])] = [
        ("Snow", [.snowfall, .piling, .screensaver]),
        ("Decorate", [.lights, .snowmen, .tree, .decorations, .countdown]),
        ("Your desktop", [.saved, .wallpapers])
    ]
}

// MARK: - Window

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?

    func show(pane: String? = nil) {
        if let p = pane, let pane = Pane(rawValue: p) {
            TinselStore.shared.pane = pane.rawValue
        }
        if window == nil {
            let root = SettingsRoot()
            let hosting = NSHostingView(rootView: root)
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 880, height: 700),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable],
                             backing: .buffered, defer: false)
            w.title = "Tinsel Settings"
            w.contentView = hosting
            w.center()
            w.setFrameAutosaveName("TinselSettings")
            w.isReleasedWhenClosed = false
            w.appearance = NSAppearance(named: .darkAqua)
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
    }

    func close() { window?.close() }
}

// MARK: - Root

struct SettingsRoot: View {
    @ObservedObject var store = TinselStore.shared

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(store: store)
                .frame(width: 232)
            Divider().overlay(Color.white.opacity(0.08))
            PaneDetail(store: store, pane: Pane(rawValue: store.pane) ?? .saved)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 640)
        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
        .preferredColorScheme(.dark)
    }
}

struct Sidebar: View {
    @ObservedObject var store: TinselStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Pane.groups, id: \.0) { group in
                        Text(group.0)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.38))
                            .padding(.horizontal, 18)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                        ForEach(group.1) { pane in
                            Button {
                                store.pane = pane.rawValue
                            } label: {
                                HStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(LinearGradient(colors: [pane.tint.opacity(0.95),
                                                                      pane.tint.opacity(0.62)],
                                                             startPoint: .top, endPoint: .bottom))
                                        .frame(width: 26, height: 26)
                                        .overlay(PaneGlyph(pane: pane, size: 13))
                                    Text(pane.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.92))
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(store.pane == pane.rawValue
                                              ? Color.white.opacity(0.12) : Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.top, 8)
            }
            Divider().overlay(Color.white.opacity(0.08))
            VStack(spacing: 8) {
                Button {
                    store.snowing.toggle()
                    (NSApp.delegate as? AppDelegate)?.status.refresh()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: store.snowing ? "stop.fill" : "snowflake")
                        Text(store.snowing ? "Stop Snowing" : "Let It Snow")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
                Button("Clear Snow") {
                    (NSApp.delegate as? AppDelegate)?.overlay.clearSnow()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.62))
            }
            .padding(12)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
    }
}

// MARK: - Pane glyph

/// SF Symbols has no snowman, so that pane gets a drawn one.
struct PaneGlyph: View {
    var pane: Pane
    var size: CGFloat = 13

    var body: some View {
        if pane == .snowmen {
            Canvas { ctx, box in
                ctx.withCGContext { cg in
                    cg.translateBy(x: 0, y: box.height)
                    cg.scaleBy(x: 1, y: -1)
                    let inset = box.width * 0.16
                    Art.snowman(cg, CGRect(x: inset, y: inset * 0.6,
                                           width: box.width - inset * 2,
                                           height: box.height - inset * 0.6),
                                radii: [30, 22, 16], props: [], tint: .white, showButtons: true)
                }
            }
            .frame(width: size * 1.6, height: size * 1.6)
        } else {
            Image(systemName: pane.symbol)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Detail

struct PaneDetail: View {
    @ObservedObject var store: TinselStore
    var pane: Pane

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                BannerHeader(pane: pane)
                    .frame(height: 208)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                VStack(alignment: .leading, spacing: 22) {
                    switchPane
                        .padding(.horizontal, 26)
                    EditingGuide()
                        .padding(.horizontal, 26)
                    Spacer(minLength: 20)
                }
            }
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder private var switchPane: some View {
        switch pane {
        case .snowfall: SnowfallPane(store: store)
        case .piling: PilingPane(store: store)
        case .screensaver: ScreenSaverPane(store: store)
        case .lights: LightsPane(store: store)
        case .snowmen: SnowmenPane(store: store)
        case .tree: TreePane(store: store)
        case .decorations: DecorationsPane(store: store)
        case .countdown: CountdownPane(store: store)
        case .saved: SavedPane(store: store)
        case .wallpapers: WallpapersPane(store: store)
        }
    }
}

struct BannerHeader: View {
    var pane: Pane
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Image(nsImage: BannerPainter.image(for: pane, size: geo.size))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.55)],
                               startPoint: .center, endPoint: .bottom)
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [pane.tint, pane.tint.opacity(0.65)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 56, height: 56)
                        .overlay(PaneGlyph(pane: pane, size: 26))
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pane.title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                        Text(pane.subtitle)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 18)
            }
        }
    }
}

// MARK: - Controls

struct SectionCard<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.055)))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.white.opacity(0.07), lineWidth: 1))
    }
}

struct ChoiceChips<T: Hashable>: View {
    var options: [(T, String)]
    @Binding var selection: T
    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.0) { option in
                Button {
                    selection = option.0
                } label: {
                    Text(option.1)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(selection == option.0 ? Color.accentColor.opacity(0.85)
                                      : Color.white.opacity(0.08))
                        )
                        .foregroundStyle(.white.opacity(selection == option.0 ? 1 : 0.75))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ToggleRow: View {
    var title: String
    var caption: String?
    @Binding var isOn: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                if let caption {
                    Text(caption).font(.system(size: 11.5)).foregroundStyle(.white.opacity(0.55))
                }
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(.switch).controlSize(.small)
        }
    }
}

struct PickerRow<T: Hashable>: View {
    var title: String
    var options: [(T, String)]
    @Binding var selection: T
    var body: some View {
        HStack {
            Text(title).font(.system(size: 13)).foregroundStyle(.white.opacity(0.9))
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.0) { o in Text(o.1).tag(o.0) }
            }
            .labelsHidden()
            .frame(width: 190)
        }
    }
}

struct EditingGuide: View {
    private let cards: [(String, String)] = [
        ("hand.draw.fill", "Click something you've put up to select it, then drag to move it."),
        ("arrow.up.left.and.arrow.down.right", "Drag its green arrow, or scroll over it, to resize."),
        ("arrow.clockwise", "Drag the round handle to turn it."),
        ("cursorarrow.click.2", "Right-click anything to take it away."),
        ("square.and.arrow.down", "Drag one out. Presents stand in the snow; stockings hang."),
        ("xmark.circle", "Press Esc, or click Done, when you're finished.")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How it works")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(cards, id: \.1) { card in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: card.0)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                        Text(card.1)
                            .font(.system(size: 11.5))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.045)))
                }
            }
        }
    }
}

struct NoteRow: View {
    var text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
            Text(text)
                .font(.system(size: 11.5))
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Art tiles

struct OrnamentTile: View {
    var kind: String
    var label: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: "#2A3D63"), Color(hex: "#1B2740")],
                                             startPoint: .top, endPoint: .bottom))
                    Canvas { ctx, size in
                        ctx.withCGContext { cg in
                            cg.translateBy(x: 0, y: size.height)
                            cg.scaleBy(x: 1, y: -1)
                            let inset = size.width * 0.14
                            Art.ornament(cg, kind,
                                         CGRect(x: inset, y: inset,
                                                width: size.width - inset * 2,
                                                height: size.height - inset * 2),
                                         tint: NSColor(red: 0.85, green: 0.20, blue: 0.24, alpha: 1))
                        }
                    }
                    if selected {
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                }
                .frame(height: 52)
                Text(label)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PropTile: View {
    var kind: String
    var label: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: "#2C4569"), Color(hex: "#1A2740")],
                                             startPoint: .top, endPoint: .bottom))
                    Canvas { ctx, size in
                        ctx.withCGContext { cg in
                            cg.translateBy(x: 0, y: size.height)
                            cg.scaleBy(x: 1, y: -1)
                            let inset = size.width * 0.18
                            Art.prop(cg, kind,
                                     CGRect(x: inset, y: inset,
                                            width: size.width - inset * 2,
                                            height: size.height - inset * 2),
                                     tint: NSColor(red: 0.85, green: 0.20, blue: 0.24, alpha: 1))
                        }
                    }
                }
                .frame(height: 48)
                Text(label)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Banner art

enum BannerPainter {
    private static var cache: [String: NSImage] = [:]

    static func image(for pane: Pane, size: CGSize) -> NSImage {
        let key = "\(pane.rawValue)-\(Int(size.width))x\(Int(size.height))"
        if let hit = cache[key] { return hit }
        let image = NSImage(size: NSSize(width: max(1, size.width), height: max(1, size.height)))
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            paint(pane, size: size, ctx: ctx)
        }
        image.unlockFocus()
        cache[key] = image
        return image
    }

    static func paintForDiagnostics(_ pane: Pane, size: CGSize, ctx: CGContext) {
        paint(pane, size: size, ctx: ctx)
    }

    private static func paint(_ pane: Pane, size: CGSize, ctx: CGContext) {
        let w = size.width, h = size.height
        let rect = CGRect(origin: .zero, size: size)
        let skies: [Pane: [String]] = [
            .snowfall: ["#0B1A2E", "#1C3A5C", "#37628C"],
            .piling: ["#141C28", "#28394E", "#4A6072"],
            .screensaver: ["#0A0E1E", "#1B1B3A", "#353560"],
            .lights: ["#0B1420", "#22182A", "#3C2438"],
            .snowmen: ["#0C1B30", "#1E3B60", "#3A6090"],
            .tree: ["#0A1A18", "#123028", "#1E4A38"],
            .decorations: ["#1A0C14", "#35141F", "#5A2030"],
            .countdown: ["#180C12", "#30121A", "#52202A"],
            .saved: ["#120E22", "#221A3C", "#382B5C"],
            .wallpapers: ["#0A1622", "#1A3248", "#2E5470"]
        ]
        let cols = (skies[pane] ?? ["#0B1A2E", "#1C3A5C", "#37628C"]).compactMap { NSColor(hex: $0) }
        Art.linearGradient(ctx, rect, cols.reversed())

        var rand = Art.seededRandom(UInt64(abs(pane.rawValue.hashValue % 90_000)) &+ 5)
        for _ in 0..<80 {
            let x = rand() * w, y = h * (0.45 + rand() * 0.55)
            ctx.setFillColor(NSColor(white: 1, alpha: 0.1 + rand() * 0.5).cgColor)
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: 1.4, height: 1.4))
        }
        // Hills
        let hills = CGMutablePath()
        hills.move(to: CGPoint(x: 0, y: 0))
        hills.addLine(to: CGPoint(x: 0, y: h * 0.16))
        hills.addCurve(to: CGPoint(x: w, y: h * 0.22),
                       control1: CGPoint(x: w * 0.32, y: h * 0.40),
                       control2: CGPoint(x: w * 0.62, y: h * 0.06))
        hills.addLine(to: CGPoint(x: w, y: 0))
        hills.closeSubpath()
        Art.fill(ctx, hills, NSColor(white: 0.93, alpha: 0.20))
        let hills2 = CGMutablePath()
        hills2.move(to: CGPoint(x: 0, y: 0))
        hills2.addLine(to: CGPoint(x: 0, y: h * 0.09))
        hills2.addCurve(to: CGPoint(x: w, y: h * 0.12),
                        control1: CGPoint(x: w * 0.40, y: h * 0.26),
                        control2: CGPoint(x: w * 0.70, y: h * 0.02))
        hills2.addLine(to: CGPoint(x: w, y: 0))
        hills2.closeSubpath()
        Art.fill(ctx, hills2, NSColor(white: 0.98, alpha: 0.30))

        // Motif per pane
        switch pane {
        case .snowmen:
            Art.snowman(ctx, CGRect(x: w * 0.66, y: h * 0.06, width: h * 0.40, height: h * 0.62),
                        radii: [30, 22, 16],
                        props: [Prop(kind: "topHat", u: 0, v: 0.95, scale: 1, angle: 0, color: "#C71A24"),
                                Prop(kind: "scarf", u: 0, v: 0.50, scale: 1, angle: 0, color: "#C71A24"),
                                Prop(kind: "carrot", u: 0.05, v: 0.60, scale: 0.9, angle: 0),
                                Prop(kind: "coal", u: -0.14, v: 0.70, scale: 0.6, angle: 0),
                                Prop(kind: "coal", u: 0.22, v: 0.70, scale: 0.6, angle: 0),
                                Prop(kind: "stickArm", u: 0.62, v: 0.55, scale: 1.2, angle: -0.2),
                                Prop(kind: "stickArm", u: -0.62, v: 0.55, scale: 1.2, angle: 0.2)])
        case .tree:
            Art.tree(ctx, CGRect(x: w * 0.62, y: h * 0.02, width: h * 0.44, height: h * 0.72),
                     ornaments: ["bauble", "star", "candycane", "bell", "bow", "snowflake"].enumerated().map { i, k in
                         Prop(kind: k, u: Double(i % 2 == 0 ? -0.4 : 0.34),
                              v: Double(i) / 2.6 - 0.9, scale: 1, angle: 0, color: "#C71A24")
                     }, seed: 9)
        case .countdown:
            Art.calendar(ctx, CGRect(x: w * 0.68, y: h * 0.10, width: h * 0.62, height: h * 0.52),
                         opened: [1, 2, 3, 5, 8], today: 9)
        case .lights:
            let d = Decoration(kind: "lights", x: 0, y: 0, hang: "free",
                               props: stride(from: 0.0, through: 1.0, by: 0.06).map { t in
                                   Prop(kind: "bulb",
                                        u: Double(w * 0.64) + Double(w * 0.30) * t,
                                        v: Double(h * 0.44) - sin(t * .pi) * Double(h * 0.10))
                               })
            var cfg = LightConfig()
            cfg.twinkle = .steady
            Lights.draw(ctx, d: d, config: cfg, time: 0.4, in: rect)
        case .decorations, .saved, .wallpapers, .snowfall, .piling, .screensaver:
            // A cluster of ornaments and pines
            for (i, kind) in ["bauble", "bell", "candycane", "star", "snowflake", "bow"].enumerated() {
                let x = w * 0.66 + CGFloat(i % 3) * w * 0.10
                let y = h * 0.36 + CGFloat(i / 3) * h * 0.20
                Art.ornament(ctx, kind, CGRect(x: x, y: y, width: h * 0.20, height: h * 0.20),
                             tint: NSColor(red: 0.85, green: 0.20, blue: 0.24, alpha: 1),
                             seed: UInt64(i + 3))
            }
            ScenePainter.drawPine(ctx, at: CGPoint(x: w * 0.90, y: h * 0.02),
                                  height: h * 0.46,
                                  color: NSColor(red: 0.07, green: 0.20, blue: 0.16, alpha: 0.9))
        }

        // Falling snow
        for _ in 0..<70 {
            let x = rand() * w, y = rand() * h
            let r = 1 + rand() * 2.4
            ctx.setFillColor(NSColor(white: 1, alpha: 0.3 + rand() * 0.55).cgColor)
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
        }
    }
}
