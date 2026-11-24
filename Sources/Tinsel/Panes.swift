import AppKit
import SwiftUI

// MARK: - Helpers

@MainActor
func startPlacing(_ mode: PlacementController.Mode) {
    guard let app = NSApp.delegate as? AppDelegate else { return }
    app.settingsWindow.close()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        app.placement.begin(mode)
    }
}

func snowmanPieceTitle(_ kind: String) -> String {
    switch kind {
    case "topHat": return "Top hat"
    case "beanie": return "Beanie"
    case "santaHat": return "Santa hat"
    case "earmuffs": return "Earmuffs"
    case "scarf": return "Scarf"
    case "mitten": return "Mitten"
    case "bowTie": return "Bow tie"
    case "coal": return "Coal"
    case "carrot": return "Carrot"
    case "pipe": return "Pipe"
    case "stickArm": return "Stick"
    case "broom": return "Broom"
    case "bucket": return "Bucket"
    case "pinecone": return "Pinecone"
    case "rock": return "Rock"
    default: return kind
    }
}

// MARK: - Snowfall

struct SnowfallPane: View {
    @ObservedObject var store: TinselStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "How much falls") {
                ChoiceChips(options: Amount.allCases.map { ($0, $0.title) },
                            selection: $store.settings.amount)
                NoteRow(text: "Snow still piles up on top of windows and widgets either way; this is only whether it's drawn falling across them.")
            }
            SectionCard(title: "The flakes") {
                ChoiceChips(options: FlakeSize.allCases.map { ($0, $0.title) },
                            selection: $store.settings.flakeSize)
                NoteRow(text: "Big soft flakes up close. Specks look like snowflake crystals far away.")
            }
            SectionCard(title: "Wind") {
                ChoiceChips(options: WindLevel.allCases.map { ($0, $0.title) },
                            selection: $store.settings.wind)
                NoteRow(text: "Still flakes fall straight down. Blowing ones drift in wind.")
            }
            SectionCard(title: "Where it falls") {
                ChoiceChips(options: Layering.allCases.map { ($0, $0.title) },
                            selection: $store.settings.layering)
                NoteRow(text: store.settings.layering.blurb)
                Divider().overlay(Color.white.opacity(0.08))
                Text("Snow behind your windows")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                ChoiceChips(options: BackgroundSnow.allCases.map { ($0, $0.title) },
                            selection: $store.settings.backgroundSnow)
                NoteRow(text: store.settings.backgroundSnow.blurb)
            }
        }
    }
}

// MARK: - Piling up

struct PilingPane: View {
    @ObservedObject var store: TinselStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Snow piles up on things") {
                ToggleRow(title: "Snow piles up on things",
                          caption: "Turn this off and the snow just falls, settling on nothing.",
                          isOn: $store.settings.piling)
                Divider().overlay(Color.white.opacity(0.08))
                Text("Depth").font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                ChoiceChips(options: Depth.allCases.map { ($0, $0.title) },
                            selection: $store.settings.depth)
                Text("Where it settles").font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                NoteRow(text: "A dusting on the bottom of the screen. Deep drifts grow, and slabs break off the edges.")
            }
            SectionCard(title: "Shaking it off") {
                ToggleRow(title: "Shake windows to knock snow off",
                          caption: "Grab a window and shake it to knock the snow off.",
                          isOn: $store.settings.shakeToClear)
                Divider().overlay(Color.white.opacity(0.08))
                ToggleRow(title: "Ice and icicles",
                          caption: "Icicles hang from window tops and drip as they melt.",
                          isOn: $store.settings.ice)
            }
            SectionCard(title: "How it builds up") {
                ChoiceChips(options: Pace.allCases.map { ($0, $0.title) },
                            selection: $store.settings.pace)
                NoteRow(text: "Slowly drifts down and settles. Quickly shakes loose and piles up fast.")
            }
        }
    }
}

// MARK: - Screen saver

struct ScreenSaverPane: View {
    @ObservedObject var store: TinselStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Snowing while you're away") {
                PickerRow(title: "Start snowing after you've been away for",
                          options: SaverAfter.allCases.map { ($0, $0.title) },
                          selection: $store.settings.saverAfter)
                Divider().overlay(Color.white.opacity(0.08))
                ToggleRow(title: "Wait while video is playing",
                          caption: "An app keeping the display awake holds the snow off.",
                          isOn: $store.settings.waitForVideo)
                ToggleRow(title: "Pile up over the menu bar",
                          caption: "Snow can fill up the menu bar too; it slides off when you're back.",
                          isOn: $store.settings.pileOverMenuBar)
                ToggleRow(title: "Only in winter (December to February)",
                          caption: "The rest of the year the screen saver stays off.",
                          isOn: $store.settings.winterOnly)
            }
            SectionCard(title: "When you come back") {
                PickerRow(title: "What happens to the snow",
                          options: SaverReturn.allCases.map { ($0, $0.title) },
                          selection: $store.settings.saverReturn)
                ToggleRow(title: "Darken the screen",
                          caption: "Your windows dim behind the snow, so it glows.",
                          isOn: $store.settings.darkenScreen)
            }
            SectionCard(title: "The Mac's own screen saver") {
                NoteRow(text: "Tinsel is an app rather than a classic screen saver, so it can snow on your real windows. If the Mac's own screen saver starts first it covers the snow, so set it to start later, or never.")
                Button("Lock Screen Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Lights

struct LightsPane: View {
    @ObservedObject var store: TinselStore

    private var lightCount: Int {
        store.decorations.filter { $0.kind == "lights" }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Look") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                          spacing: 10) {
                    ForEach(LightStyle.allCases) { style in
                        Button {
                            store.settings.lights.style = style
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(Color.black.opacity(0.35))
                                    Canvas { ctx, size in
                                        ctx.withCGContext { cg in
                                            drawPreview(cg, size: size, style: style)
                                        }
                                    }
                                }
                                .frame(height: 46)
                                Text(style.title)
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                            .overlay(RoundedRectangle(cornerRadius: 9)
                                .stroke(store.settings.lights.style == style
                                        ? Color.accentColor : .clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Divider().overlay(Color.white.opacity(0.08))
                Text("How they light up").font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                ChoiceChips(options: TwinkleStyle.allCases.map { ($0, $0.title) },
                            selection: $store.settings.lights.twinkle)
                Text("Speed").font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Slider(value: $store.settings.lights.speed, in: 0...1)
                    .tint(.accentColor)
                Text("Bulbs").font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                ChoiceChips(options: BulbSize.allCases.map { ($0, $0.title) },
                            selection: $store.settings.lights.density)
            }
            SectionCard(title: "Colors") {
                HStack(spacing: 8) {
                    Button {
                        store.settings.lights.colorIndex = -1
                    } label: {
                        Text("Any color")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(store.settings.lights.colorIndex == -1
                                                          ? 0.22 : 0.07)))
                    }
                    .buttonStyle(.plain)
                    ForEach(Array(ornamentPalette.enumerated()), id: \.offset) { i, hex in
                        Button {
                            store.settings.lights.colorIndex = i
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 20, height: 20)
                                .overlay(Circle().stroke(.white.opacity(
                                    store.settings.lights.colorIndex == i ? 0.9 : 0.15),
                                    lineWidth: store.settings.lights.colorIndex == i ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                NoteRow(text: "Changes show on those lights as you make them.")
            }
            SectionCard(title: "String them up") {
                HStack {
                    Button {
                        startPlacing(.lights)
                    } label: {
                        Label("String Them Up", systemImage: "lightbulb.2.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    Spacer()
                    if lightCount > 0 {
                        Text("\(lightCount) up now")
                            .font(.system(size: 11.5))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                NoteRow(text: "Then click a window to string them on it. They follow it around and never get in the way of dragging it.")
            }
        }
    }

    private func drawPreview(_ cg: CGContext, size: CGSize, style: LightStyle) {
        let w = size.width, h = size.height
        var cfg = LightConfig()
        cfg.style = style
        cfg.twinkle = .steady
        let d = Decoration(kind: "lights", x: 0, y: 0, hang: "free",
                           props: stride(from: 0.0, through: 1.0, by: 0.08).map { t in
                               Prop(kind: "bulb", u: Double(w) * (0.08 + 0.84 * t),
                                    v: Double(h) * 0.55 - sin(t * .pi) * Double(h) * 0.16)
                           })
        Lights.draw(cg, d: d, config: cfg, time: 0.2, in: CGRect(origin: .zero, size: size))
    }
}

// MARK: - Snowmen

struct SnowmenPane: View {
    @ObservedObject var store: TinselStore

    private let hats = ["topHat", "beanie", "santaHat", "earmuffs"]
    private let extras = ["scarf", "mitten", "bowTie", "pipe", "broom", "bucket", "pinecone", "rock"]
    private let faces = ["coal", "carrot"]
    private let arms = ["stickArm"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Snowballs") {
                HStack(spacing: 10) {
                    Button {
                        startPlacing(.snowman)
                    } label: {
                        Label("Roll a Snowball", systemImage: "circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    if snowmanCount > 0 {
                        Text("\(snowmanCount) built")
                            .font(.system(size: 11.5))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                }
                NoteRow(text: "Drag a snowball onto the desktop or a window's top, then more on top, as many as you like.")
            }
            SectionCard(title: "Hats") {
                pieceRow(hats)
                Divider().overlay(Color.white.opacity(0.08))
                Text("Scarves and mittens").font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                pieceRow(["scarf", "mitten", "bowTie"])
            }
            SectionCard(title: "Faces, arms and extras") {
                pieceRow(faces + arms)
                Divider().overlay(Color.white.opacity(0.08))
                pieceRow(extras)
                NoteRow(text: "Drag hats, sticks, coal and carrots anywhere on it. Each snaps to the right size.")
            }
            SectionCard(title: "Or put up a ready-made snowman") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The one in the banner, top hat to carrot nose.")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.75))
                        Text("Click where it goes; then change any piece of it, just like one you built.")
                            .font(.system(size: 11.5))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Button {
                        putReadySnowman()
                    } label: {
                        Label("Put One Up", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var snowmanCount: Int { store.decorations.filter { $0.kind == "snowman" }.count }

    private func pieceRow(_ kinds: [String]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                  spacing: 8) {
            ForEach(kinds, id: \.self) { kind in
                PropTile(kind: kind, label: snowmanPieceTitle(kind)) {
                    startPlacing(.snowmanPiece(kind))
                }
            }
        }
    }

    private func putReadySnowman() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let size = screen.frame.size
        var d = Decoration(kind: "snowman",
                           x: Double(size.width * 0.72), y: Double(size.height * 0.34),
                           screen: 0, height: 210, radii: [34, 25, 18], seed: 20_261_224)
        d.props = [
            Prop(kind: "stickArm", u: 0.56, v: 0.30, scale: 1.3, angle: -0.25),
            Prop(kind: "stickArm", u: -0.56, v: 0.30, scale: 1.3, angle: 0.25),
            Prop(kind: "coal", u: -0.10, v: 0.64, scale: 0.85, angle: 0),
            Prop(kind: "coal", u: 0.10, v: 0.64, scale: 0.85, angle: 0),
            Prop(kind: "carrot", u: 0.02, v: 0.58, scale: 0.85, angle: 0),
            Prop(kind: "scarf", u: 0, v: 0.30, scale: 1, angle: 0, color: "#C71A24"),
            Prop(kind: "topHat", u: 0, v: 0.94, scale: 1, angle: 0, color: "#C71A24")
        ]
        store.add(d)
        store.bringBackEverything()
    }
}

// MARK: - Tree

struct TreePane: View {
    @ObservedObject var store: TinselStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "The tree") {
                HStack {
                    Button {
                        startPlacing(.tree)
                    } label: {
                        Label("Put Up a Tree", systemImage: "tree.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                    Text("\(treeCount) up")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.55))
                }
                NoteRow(text: "Select the tree itself to resize it; its ornaments grow with it.")
            }
            SectionCard(title: "Ornaments") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                          spacing: 8) {
                    ForEach(Catalogue.allOrnaments, id: \.self) { kind in
                        OrnamentTile(kind: kind, label: Catalogue.title(kind), selected: false) {
                            startPlacing(.ornament(kind))
                        }
                    }
                }
                NoteRow(text: "Drag ornaments onto the tree, anywhere, as many as you like. A star or angel near the top crowns it.")
            }
        }
    }

    private var treeCount: Int { store.decorations.filter { $0.kind == "tree" }.count }
}

// MARK: - Decorations

struct DecorationsPane: View {
    @ObservedObject var store: TinselStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Presents, lanterns and reindeer") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                          spacing: 8) {
                    ForEach(Catalogue.standing, id: \.self) { kind in
                        OrnamentTile(kind: kind, label: Catalogue.title(kind), selected: false) {
                            startPlacing(.ornament(kind))
                        }
                    }
                }
                NoteRow(text: "These stand in the snow. Click where one goes, then drag it to move it.")
            }
            SectionCard(title: "Stockings, holly and wreaths") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                          spacing: 8) {
                    ForEach(Catalogue.hanging, id: \.self) { kind in
                        OrnamentTile(kind: kind, label: Catalogue.title(kind), selected: false) {
                            if kind == "wreath" { startPlacing(.wreath) }
                            else { startPlacing(.ornament(kind)) }
                        }
                    }
                }
                NoteRow(text: "These hang wherever you click. Right-click anything to take it away.")
            }
            SectionCard(title: "Baubles and bows") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                          spacing: 8) {
                    ForEach(["bauble", "bow", "candycane", "star", "angel", "snowflake"],
                            id: \.self) { kind in
                        OrnamentTile(kind: kind, label: Catalogue.title(kind), selected: false) {
                            startPlacing(.ornament(kind))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Countdown

struct CountdownPane: View {
    @ObservedObject var store: TinselStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Countdown calendar") {
                HStack {
                    Button {
                        startPlacing(.calendar)
                    } label: {
                        Label("Put Up the Calendar", systemImage: "calendar")
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                    Text(calendarCount > 0 ? "\(calendarCount) up" : "Not up")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.55))
                }
                NoteRow(text: "One more door each day from the day you hang it, and in December, every door up to the date.")
                NoteRow(text: "Click a door that isn't ready and it tells you how many sleeps to go.")
                NoteRow(text: "Right-click the calendar to take it down. Its opened doors are remembered.")
            }
            SectionCard(title: "This year") {
                HStack(spacing: 10) {
                    Image(systemName: Advent.sleepsTillChristmas == 0 ? "gift.fill" : "moon.stars.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                    Text(Advent.sleepsTillChristmas == 0
                         ? "Merry Christmas!"
                         : (Advent.sleepsTillChristmas == 1
                            ? "One more sleep till Christmas"
                            : "\(Advent.sleepsTillChristmas) sleeps till Christmas"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                if Advent.isDecember {
                    Text("Doors up to \(Advent.today) are ready today.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
    }

    private var calendarCount: Int { store.decorations.filter { $0.kind == "calendar" }.count }
}

// MARK: - My Decorations

struct SavedPane: View {
    @ObservedObject var store: TinselStore
    @State private var newLookName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Everything that's up") {
                if store.decorations.isEmpty {
                    Text("Nothing's up right now.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    HStack(spacing: 16) {
                        stat("\(store.decorations.count)", "pieces up")
                        stat("\(store.decorations.filter { $0.kind == "snowman" }.count)", "snowmen")
                        stat("\(store.decorations.filter { $0.kind == "tree" }.count)", "trees")
                        stat("\(store.decorations.filter { $0.kind == "lights" }.count)", "light strings")
                        Spacer()
                    }
                }
                HStack(spacing: 8) {
                    Button(store.decorationsShown ? "Put Away Decorations" : "Bring Back Decorations") {
                        store.decorationsShown.toggle()
                    }
                    .buttonStyle(.bordered)
                    Button("Take Everything Down") {
                        store.removeAll()
                        (NSApp.delegate as? AppDelegate)?.placement.end()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                NoteRow(text: "What's up now can come back later with Bring Back.")
            }
            SectionCard(title: "Save This Look") {
                HStack {
                    TextField("My Christmas look", text: $newLookName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                    Button("Save This Look") {
                        store.saveLook(named: newLookName)
                        newLookName = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.decorations.isEmpty)
                }
                NoteRow(text: "Save a look to put it up again any time: one for Christmas Eve, one for the office.")
            }
            SectionCard(title: "Saved looks") {
                if store.looks.isEmpty {
                    Text("Nothing saved yet.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    ForEach(store.looks) { look in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(look.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                Text("\(look.items.count) pieces · \(look.created.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Spacer()
                            Button("Put Up") {
                                store.applyLook(look)
                                store.bringBackEverything()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            Button {
                                store.deleteLook(look)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.vertical, 4)
                        Divider().overlay(Color.white.opacity(0.06))
                    }
                }
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
            Text(label).font(.system(size: 10.5)).foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Wallpapers

struct WallpapersPane: View {
    @ObservedObject var store: TinselStore
    @State private var applied: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Christmas desktop pictures") {
                NoteRow(text: "Click one to make it your desktop picture on every display. Change it back any time in System Settings, under Wallpaper.")
                HStack {
                    Button {
                        let spec = Scenes.all.randomElement() ?? Scenes.all[0]
                        if WallpaperManager.apply(spec) { applied = spec.name }
                    } label: {
                        Label("Surprise me", systemImage: "sparkles")
                    }
                    .buttonStyle(.bordered)
                    if let applied {
                        Text("Set \(applied)")
                            .font(.system(size: 11.5))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                      spacing: 12) {
                ForEach(Scenes.all, id: \.name) { spec in
                    Button {
                        if WallpaperManager.apply(spec) { applied = spec.name }
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Image(nsImage: WallpaperManager.preview(spec, size: CGSize(width: 220, height: 140)))
                                .resizable()
                                .aspectRatio(1.55, contentMode: .fill)
                                .frame(height: 96)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(spec.name)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
