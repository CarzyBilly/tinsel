import AppKit
import Combine
import SwiftUI

// MARK: - Snow settings

enum Amount: String, Codable, CaseIterable, Identifiable {
    case flurries, steady, blizzard
    var id: String { rawValue }
    var title: String {
        switch self {
        case .flurries: return "Flurries"
        case .steady: return "Steady"
        case .blizzard: return "Blizzard"
        }
    }
    var rate: Double {
        switch self {
        case .flurries: return 0.35
        case .steady: return 1.0
        case .blizzard: return 2.4
        }
    }
}

enum FlakeSize: String, Codable, CaseIterable, Identifiable {
    case specks, small, big, huge
    var id: String { rawValue }
    var title: String {
        switch self {
        case .specks: return "Specks"
        case .small: return "Small"
        case .big: return "Big"
        case .huge: return "Huge"
        }
    }
    var range: ClosedRange<Double> {
        switch self {
        case .specks: return 0.6...1.4
        case .small: return 1.2...2.4
        case .big: return 2.2...4.4
        case .huge: return 3.6...7.0
        }
    }
}

enum WindLevel: String, Codable, CaseIterable, Identifiable {
    case still, gusty, blowing
    var id: String { rawValue }
    var title: String {
        switch self {
        case .still: return "Still"
        case .gusty: return "Gusty"
        case .blowing: return "Blowing"
        }
    }
    var strength: Double {
        switch self {
        case .still: return 6
        case .gusty: return 34
        case .blowing: return 78
        }
    }
}

/// Where the falling snow is drawn relative to other windows.
enum Layering: String, Codable, CaseIterable, Identifiable {
    case behindEverything, aboveWindows
    var id: String { rawValue }
    var title: String {
        switch self {
        case .behindEverything: return "Behind your windows"
        case .aboveWindows: return "In front of everything"
        }
    }
    var blurb: String {
        switch self {
        case .behindEverything:
            return "Snow falls only behind everything, like a snowy wallpaper, and never piles up. The screen saver is off."
        case .aboveWindows:
            return "Snow falls across your windows too, and settles on their tops."
        }
    }
}

enum BackgroundSnow: String, Codable, CaseIterable, Identifiable {
    case off, gentle, allDay
    var id: String { rawValue }
    var title: String {
        switch self {
        case .off: return "Off"
        case .gentle: return "Only behind them"
        case .allDay: return "All day, as well"
        }
    }
    var blurb: String {
        switch self {
        case .off: return "No snow behind your windows."
        case .gentle: return "A gentle snowfall on the desktop, behind every window, that never piles up."
        case .allDay: return "A gentle snowfall behind your windows all day, as well as the snow above. It never piles up."
        }
    }
}

enum Depth: String, Codable, CaseIterable, Identifiable {
    case dusting, deep
    var id: String { rawValue }
    var title: String { self == .dusting ? "A dusting" : "Deep" }
}

enum Pace: String, Codable, CaseIterable, Identifiable {
    case slowly, quickly
    var id: String { rawValue }
    var title: String { self == .slowly ? "Slowly" : "Quickly" }
    var factor: Double { self == .slowly ? 0.65 : 1.6 }
}

enum SaverAfter: String, Codable, CaseIterable, Identifiable {
    case off, one, five, ten, fifteen, thirty, hour
    var id: String { rawValue }
    var title: String {
        switch self {
        case .off: return "Off"
        case .one: return "1 min"
        case .five: return "5 min"
        case .ten: return "10 min"
        case .fifteen: return "15 min"
        case .thirty: return "30 min"
        case .hour: return "1 hour"
        }
    }
    /// Seconds of idle time, nil when the screen saver snow is off.
    var seconds: Double? {
        switch self {
        case .off: return nil
        case .one: return 60
        case .five: return 300
        case .ten: return 600
        case .fifteen: return 900
        case .thirty: return 1800
        case .hour: return 3600
        }
    }
}

enum SaverReturn: String, Codable, CaseIterable, Identifiable {
    case melt, darken
    var id: String { rawValue }
    var title: String { self == .melt ? "The snow that's left melts" : "Darken the screen" }
}

enum LightStyle: String, Codable, CaseIterable, Identifiable {
    case classic, bigRetro, warmWhite, icyBlue, mini, candyCane
    var id: String { rawValue }
    var title: String {
        switch self {
        case .classic: return "Classic"
        case .bigRetro: return "Big Retro"
        case .warmWhite: return "Warm White"
        case .icyBlue: return "Icy Blue"
        case .mini: return "Mini"
        case .candyCane: return "Candy Cane"
        }
    }
    var palette: [NSColor] {
        switch self {
        case .classic:
            return [NSColor(red: 0.95, green: 0.18, blue: 0.20, alpha: 1),
                    NSColor(red: 0.20, green: 0.78, blue: 0.36, alpha: 1),
                    NSColor(red: 0.98, green: 0.78, blue: 0.22, alpha: 1),
                    NSColor(red: 0.26, green: 0.52, blue: 1.00, alpha: 1)]
        case .bigRetro:
            return [NSColor(red: 1.00, green: 0.62, blue: 0.16, alpha: 1),
                    NSColor(red: 1.00, green: 0.30, blue: 0.36, alpha: 1),
                    NSColor(red: 0.42, green: 0.84, blue: 0.62, alpha: 1)]
        case .warmWhite:
            return [NSColor(red: 1.00, green: 0.94, blue: 0.78, alpha: 1),
                    NSColor(red: 1.00, green: 0.86, blue: 0.60, alpha: 1)]
        case .icyBlue:
            return [NSColor(red: 0.72, green: 0.90, blue: 1.00, alpha: 1),
                    NSColor(red: 0.52, green: 0.78, blue: 1.00, alpha: 1)]
        case .mini:
            return [NSColor(red: 1.00, green: 0.42, blue: 0.46, alpha: 1),
                    NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1),
                    NSColor(red: 0.42, green: 0.80, blue: 0.98, alpha: 1)]
        case .candyCane:
            return [NSColor(red: 0.98, green: 0.24, blue: 0.28, alpha: 1),
                    NSColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1)]
        }
    }
}

enum TwinkleStyle: String, Codable, CaseIterable, Identifiable {
    case steady, alternate, chase, wave, slowFade, blink
    var id: String { rawValue }
    var title: String {
        switch self {
        case .steady: return "Steady"
        case .alternate: return "Alternate"
        case .chase: return "Chase"
        case .wave: return "Wave"
        case .slowFade: return "Slow fade"
        case .blink: return "Blink"
        }
    }
}

enum BulbSize: String, Codable, CaseIterable, Identifiable {
    case sparse, packed
    var id: String { rawValue }
    var title: String { self == .sparse ? "Sparse" : "Packed" }
}

struct LightConfig: Codable, Equatable {
    var style: LightStyle = .classic
    var twinkle: TwinkleStyle = .chase
    var speed: Double = 0.5          // 0 slow … 1 quick
    var density: BulbSize = .sparse
    var colorIndex: Int = 0          // -1: multi
}

// MARK: - Decoration model

struct Prop: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: String          // "topHat", "coal", "carrot", "bauble", …
    var u: Double = 0         // -1 … 1 in the host's local box
    var v: Double = 0
    var scale: Double = 1
    var angle: Double = 0
    var color: String? = nil
}

struct Decoration: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: String              // "snowman", "tree", "calendar", "ornament", "lights", "wreath"
    var ornament: String? = nil   // for kind == "ornament"
    var x: Double = 0
    var y: Double = 0
    var screen: Int = 0
    var height: Double = 160
    var width: Double = 0
    var radii: [Double] = []
    /// When the item is attached to another app's window, these follow it around.
    var windowPid: Int32? = nil
    var windowIndex: Int? = nil
    var hang: String = "free"     // "free" | "top"
    var seed: UInt64 = 0
    var angle: Double = 0
    var tint: String? = nil
    var z: Double = 0
    var props: [Prop] = []
}

struct SavedLook: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var items: [Decoration]
    var created: Date = Date()
}

// MARK: - Settings bundle

struct SnowSettings: Codable, Equatable {
    var amount: Amount = .steady
    var flakeSize: FlakeSize = .small
    var wind: WindLevel = .gusty
    var layering: Layering = .behindEverything
    var backgroundSnow: BackgroundSnow = .gentle
    var piling: Bool = true
    var depth: Depth = .dusting
    var ice: Bool = true
    var pace: Pace = .slowly
    var shakeToClear: Bool = true
    var saverAfter: SaverAfter = .off
    var saverReturn: SaverReturn = .melt
    var darkenScreen: Bool = false
    var pileOverMenuBar: Bool = false
    var waitForVideo: Bool = true
    var lights = LightConfig()
    var showMenuBarIcon: Bool = true
    var winterOnly: Bool = false
}

// MARK: - Persistence + app state

@MainActor
final class TinselStore: ObservableObject {
    static let shared = TinselStore()

    @Published var settings = SnowSettings() { didSet { scheduleSave() } }
    @Published var decorations: [Decoration] = [] { didSet { scheduleSave() } }
    @Published var looks: [SavedLook] = [] { didSet { scheduleSave() } }
    @Published var snowing: Bool = true { didSet { scheduleSave(); onSnowingChanged?(snowing) } }
    @Published var decorationsShown: Bool = true { didSet { scheduleSave(); onDecorationsChanged?(decorationsShown) } }
    @Published var pane: String = "saved" { didSet { defaults.set(pane, forKey: "settingsPane") } }
    /// Advances when a decoration's art should be redrawn (opened advent doors, etc.).
    @Published var artGeneration: Int = 0
    @Published var isSaverGlow: Bool = false
    @Published var hint: String? = nil

    var onSnowingChanged: ((Bool) -> Void)?
    var onDecorationsChanged: ((Bool) -> Void)?
    var onArtChanged: (() -> Void)?

    private let defaults: UserDefaults
    private let stateKey = "tinsel.state.v2"
    private var saveTask: Task<Void, Never>?

    struct Snapshot: Codable {
        var settings: SnowSettings
        var decorations: [Decoration]
        var looks: [SavedLook]
        var snowing: Bool
        var decorationsShown: Bool
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: stateKey),
           let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
            settings = snap.settings
            decorations = snap.decorations
            looks = snap.looks
            snowing = snap.snowing
            decorationsShown = snap.decorationsShown
        }
        if let p = defaults.string(forKey: "settingsPane") { pane = p }
    }

    // MARK: Saving

    private func scheduleSave() {
        saveTask?.cancel()
        let snap = Snapshot(settings: settings, decorations: decorations,
                            looks: looks, snowing: snowing, decorationsShown: decorationsShown)
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled, let self else { return }
            if let data = try? JSONEncoder().encode(snap) {
                self.defaults.set(data, forKey: self.stateKey)
            }
        }
    }

    func flush() {
        let snap = Snapshot(settings: settings, decorations: decorations,
                            looks: looks, snowing: snowing, decorationsShown: decorationsShown)
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: stateKey)
        }
    }

    // MARK: Decorations

    func add(_ d: Decoration) {
        decorations.append(d)
        bumpArt()
    }

    func update(_ d: Decoration) {
        if let i = decorations.firstIndex(where: { $0.id == d.id }) {
            decorations[i] = d
            bumpArt()
        }
    }

    func remove(id: UUID) {
        decorations.removeAll { $0.id == id || $0.props.contains(where: { $0.id == id }) }
        bumpArt()
    }

    func removeAll() {
        decorations.removeAll()
        bumpArt()
    }

    func bumpArt() {
        artGeneration &+= 1
        onArtChanged?()
    }

    // MARK: Looks

    func saveLook(named name: String) {
        let look = SavedLook(name: name.isEmpty ? "My Christmas look" : name, items: decorations)
        looks.insert(look, at: 0)
    }

    func applyLook(_ look: SavedLook) {
        decorations = look.items
        bumpArt()
    }

    func renameLook(_ look: SavedLook, to name: String) {
        guard let i = looks.firstIndex(where: { $0.id == look.id }) else { return }
        looks[i].name = name
    }

    func deleteLook(_ look: SavedLook) {
        looks.removeAll { $0.id == look.id }
    }

    func putAwayEverything() {
        decorationsShown = false
    }

    func bringBackEverything() {
        decorationsShown = true
    }

    // MARK: Advent

    /// Opened doors live in the decoration's props: kind "door", color = day.
    func openedDoors(for decoration: Decoration) -> Set<Int> {
        Set(decoration.props.filter { $0.kind == "door" }.compactMap { Int($0.color ?? "") })
    }

    func markDoor(_ day: Int, on decoration: Decoration) {
        guard let i = decorations.firstIndex(where: { $0.id == decoration.id }) else { return }
        if !decorations[i].props.contains(where: { $0.kind == "door" && $0.color == "\(day)" }) {
            decorations[i].props.append(Prop(kind: "door", u: 0, v: 0, scale: 1, angle: 0, color: "\(day)"))
            bumpArt()
        }
    }
}

// MARK: - Colour helpers

extension NSColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        let r, g, b, a: Double
        if s.count == 8 {
            r = Double((v >> 24) & 0xFF) / 255
            g = Double((v >> 16) & 0xFF) / 255
            b = Double((v >> 8) & 0xFF) / 255
            a = Double(v & 0xFF) / 255
        } else {
            r = Double((v >> 16) & 0xFF) / 255
            g = Double((v >> 8) & 0xFF) / 255
            b = Double(v & 0xFF) / 255
            a = 1
        }
        self.init(srgbRed: r, green: g, blue: b, alpha: a)
    }

    var hexString: String {
        let c = usingColorSpace(.sRGB) ?? self
        return String(format: "#%02X%02X%02X",
                      Int((c.redComponent * 255).rounded()),
                      Int((c.greenComponent * 255).rounded()),
                      Int((c.blueComponent * 255).rounded()))
    }
}

extension Color {
    init(hex: String, fallback: Color = .red) {
        if let ns = NSColor(hex: hex) { self.init(nsColor: ns) } else { self = fallback }
    }
}

let ornamentPalette: [String] = ["#C71A24", "#0F8A3C", "#E8B22A", "#2F6FE4",
                                 "#E2579C", "#7A4ED2", "#F2F0E6", "#C0C6CC"]
