import AppKit
import QuartzCore

// MARK: - Overlay windows

/// A borderless, click-through window that sits above or below other windows
/// and never takes focus.
final class SnowPanel: NSPanel {
    init(screen: NSScreen, level: NSWindow.Level) {
        super.init(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        self.level = level
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary,
                              .transient]
        let view = OverlayView(frame: screen.frame)
        contentView = view
        setFrame(screen.frame, display: false)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

/// Draws the snow field, the snow caps on other windows and every decoration.
final class OverlayView: NSView {
    var scene = SnowScene(seed: 1)
    var drawsSnow = true
    var drawsDecorations = false
    var decorations: [Decoration] = []
    var windowCaps: [CGRect] = []
    var icicles: [(x: Double, top: Double, seed: UInt64)] = []
    var lightConfig = LightConfig()
    var time: Double = 0
    var decorationsVisible = true
    var saverGlow = false

    override var isOpaque: Bool { false }
    override var acceptsFirstResponder: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        if saverGlow {
            ctx.setFillColor(NSColor(white: 0, alpha: 0.55).cgColor)
            ctx.fill(bounds)
        }
        if drawsSnow {
            scene.draw(in: ctx, bounds: bounds, icicles: icicles)
            scene.drawCaps(in: ctx, rects: windowCaps)
        }
        if drawsDecorations && decorationsVisible {
            for d in decorations.sorted(by: { $0.z < $1.z }) {
                draw(d, in: ctx)
            }
        }
    }

    private func draw(_ d: Decoration, in ctx: CGContext) {
        let r = d.displayRect(in: bounds)
        switch d.kind {
        case "snowman":
            Art.snowman(ctx, r, radii: d.radii, props: d.props,
                        tint: NSColor(hex: d.tint ?? "#FFFFFF") ?? .white)
        case "tree":
            Art.tree(ctx, r, ornaments: d.props, seed: d.seed)
        case "calendar":
            let opened = Set(d.props.filter { $0.kind == "door" }.compactMap { Int($0.color ?? "") })
            Art.calendar(ctx, r, opened: opened, today: Advent.today)
        case "ornament":
            Art.ornament(ctx, d.ornament ?? "bauble", r,
                         tint: NSColor(hex: d.tint ?? "#C71A24") ?? .red, seed: d.seed)
            if d.hang == "top" {
                let thread = CGMutablePath()
                thread.move(to: CGPoint(x: r.midX, y: r.maxY))
                thread.addLine(to: CGPoint(x: r.midX, y: r.maxY + 16))
                Art.stroke(ctx, thread, NSColor(white: 0.85, alpha: 0.5), 1)
            }
        case "wreath":
            Art.unit(ctx, r) { Art.drawWreath(ctx) }
        case "lights":
            Lights.draw(ctx, d: d, config: lightConfig, time: time, in: bounds)
        default:
            Art.ornament(ctx, "bauble", r, tint: NSColor(hex: d.tint ?? "#C71A24") ?? .red)
        }
    }
}

// MARK: - Overlay controller

@MainActor
final class OverlayController {
    private(set) var panels: [(screen: NSScreen, back: SnowPanel, front: SnowPanel)] = []
    private var timer: Timer?
    private var lastTick = CACurrentMediaTime()
    private var settings = SnowSettings()
    private var time: Double = 0
    private var capsRefresh: Double = 0
    weak var placement: PlacementController?

    var decorations: [Decoration] = [] { didSet { refreshViews() } }
    var visible = true { didSet { refreshViews() } }
    var snowing = true
    var saverGlow = false { didSet { refreshViews() } }

    func start(store: TinselStore, placement: PlacementController) {
        self.placement = placement
        self.settings = store.settings
        self.decorations = store.decorations
        self.snowing = store.snowing
        rebuildPanels()
        applyLevels()
        store.onSnowingChanged = { [weak self] on in
            self?.snowing = on
        }
        store.onDecorationsChanged = { [weak self] on in
            self?.visible = on
        }
        store.onArtChanged = { [weak self] in
            guard let self else { return }
            self.decorations = TinselStore.shared.decorations
            self.refreshViews()
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                              object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildPanels()
                self?.applyLevels()
            }
        }
        lastTick = CACurrentMediaTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func update(settings: SnowSettings) {
        let layeringChanged = settings.layering != self.settings.layering
        self.settings = settings
        if layeringChanged { applyLevels() }
        refreshViews()
    }

    func setDecorations(_ items: [Decoration]) {
        decorations = items
    }

    func rebuildPanels() {
        for p in panels {
            p.back.orderOut(nil)
            p.front.orderOut(nil)
            p.back.close()
            p.front.close()
        }
        panels.removeAll()
        for screen in NSScreen.screens {
            let back = SnowPanel(screen: screen, level: .init(rawValue: 18))
            let front = SnowPanel(screen: screen, level: .init(rawValue: 19))
            if let v = back.contentView as? OverlayView {
                v.drawsSnow = settings.backgroundSnow != .off
                v.drawsDecorations = true
                v.scene = SnowScene(seed: UInt64(screen.frame.width) &+ 11)
            }
            if let v = front.contentView as? OverlayView {
                v.drawsSnow = true
                v.scene = SnowScene(seed: UInt64(screen.frame.height) &+ 29)
            }
            back.orderFrontRegardless()
            front.orderFrontRegardless()
            panels.append((screen, back, front))
        }
    }

    /// Window levels: behind everything (above the wallpaper and desktop icons)
    /// or above normal windows but below the Dock and the menu bar.
    func applyLevels() {
        let behind: NSWindow.Level
        if settings.layering == .behindEverything {
            behind = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        } else {
            behind = NSWindow.Level(rawValue: 18)
        }
        for p in panels {
            p.back.level = behind
            p.front.level = behind
            p.back.ignoresMouseEvents = true
            p.front.ignoresMouseEvents = true
            p.back.orderFrontRegardless()
            p.front.orderFrontRegardless()
        }
    }

    func refreshViews() {
        for p in panels {
            if let v = p.back.contentView as? OverlayView {
                v.decorations = decorations
                v.decorationsVisible = visible
                v.lightConfig = settings.lights
                v.saverGlow = saverGlow
                v.drawsSnow = settings.backgroundSnow != .off
                v.needsDisplay = true
            }
            if let v = p.front.contentView as? OverlayView {
                v.decorations = decorations
                v.decorationsVisible = visible
                v.lightConfig = settings.lights
                v.saverGlow = saverGlow
                v.drawsSnow = settings.layering == .aboveWindows
                v.needsDisplay = true
            }
        }
    }

    private func tick() {
        let now = CACurrentMediaTime()
        var dt = now - lastTick
        lastTick = now
        dt = min(dt, 0.1)
        time += dt

        capsRefresh -= dt
        var caps: [CGRect] = []
        var icicles: [(Double, Double, UInt64)] = []
        if capsRefresh <= 0 {
            capsRefresh = 0.75
            let tracked = WindowTracker.shared.surfaces()
            for p in panels {
                var local: [CGRect] = []
                for s in tracked {
                    let r = WindowTracker.cocoaRect(s.rect)
                    let lx = r.minX - p.screen.frame.minX
                    let ly = r.minY - p.screen.frame.minY
                    let ratio = (r.width * r.height) / max(1, p.screen.frame.width * p.screen.frame.height)
                    // Skip desktop, wallpaper and near-full-screen surfaces: they are not
                    // something snow can visibly settle on the top of.
                    if ratio > 0.55 { continue }
                    if r.height > p.screen.frame.height * 0.86 { continue }
                    if r.maxX > p.screen.frame.minX && r.minX < p.screen.frame.maxX {
                        local.append(CGRect(x: lx, y: ly, width: r.width, height: r.height))
                    }
                }
                p.back.contentView?.needsDisplay = true
                if let v = p.back.contentView as? OverlayView { v.windowCaps = local }
                if let v = p.front.contentView as? OverlayView { v.windowCaps = local }
                if p.screen == panels.first?.screen {
                    caps = local
                    icicles = local.map { (Double($0.minX) + 20, Double($0.maxY), UInt64(abs($0.minX))) }
                }
            }
        }

        for p in panels {
            guard let v = p.back.contentView as? OverlayView,
                  let f = p.front.contentView as? OverlayView else { continue }
            let active = snowing
            let backIntensity = settings.backgroundSnow == .allDay ? 0.6 : 0.45
            if v.drawsSnow && active {
                v.scene.configure(size: v.bounds.size, settings: settings,
                                  intensity: backIntensity, piling: false)
                v.scene.step(dt)
            } else if !active {
                v.scene.melt(dt)
            }
            if f.drawsSnow && active {
                f.scene.configure(size: f.bounds.size, settings: settings,
                                  intensity: 1.0, piling: settings.piling)
                f.scene.step(dt)
            } else if !active {
                f.scene.melt(dt)
            }
            v.icicles = icicles
            f.icicles = icicles
            v.time = time
            f.time = time
            v.needsDisplay = true
            f.needsDisplay = true
        }
        _ = caps
    }

    func clearSnow() {
        for p in panels {
            (p.back.contentView as? OverlayView)?.scene.clearPile()
            (p.front.contentView as? OverlayView)?.scene.clearPile()
        }
    }

    func shake(at rect: CGRect) {
        for p in panels {
            for v in [p.back.contentView, p.front.contentView].compactMap({ $0 as? OverlayView }) {
                if rect.intersects(p.screen.frame) {
                    v.scene.clearPile()
                }
            }
        }
    }
}
