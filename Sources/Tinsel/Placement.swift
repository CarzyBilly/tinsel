import AppKit
import SwiftUI

// MARK: - Placing and editing

/// Owns the interactive layer used while something is being put up: the hint
/// bar at the bottom, the selection handles, and all the mouse handling.
@MainActor
final class PlacementController {
    enum Mode: Equatable {
        case none
        case ornament(String)
        case tree
        case calendar
        case wreath
        case snowman
        case snowmanPiece(String)
        case lights
        case edit
    }

    var mode: Mode = .none { didSet { refresh() } }
    var overlay: OverlayController?
    var store: TinselStore { TinselStore.shared }

    private var windows: [PlacementWindow] = []
    private var selected: UUID?
    private var dragOrigin: CGPoint?
    private var startRect: CGRect = .zero
    private var currentScreen: NSScreen?
    private var rowAnchor: CGPoint?
    private var hintText: String?

    var selection: UUID? { selected }

    // MARK: lifecycle

    func install() {
        rebuild()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                              object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.rebuild() }
        }
    }

    private func rebuild() {
        for w in windows { w.orderOut(nil); w.close() }
        windows.removeAll()
        for screen in NSScreen.screens {
            let w = PlacementWindow(screen: screen, controller: self)
            windows.append(w)
        }
    }

    func refresh() {
        let active = mode != .none
        for w in windows {
            w.setVisible(active)
        }
        if active {
            windows.first?.makeKey()
        }
        overlay?.refreshViews()
    }

    func begin(_ m: Mode) {
        if mode == m { end(); return }
        mode = m
        selected = nil
        rowAnchor = nil
        hintText = Self.hint(for: m)
        refresh()
        overlay?.refreshViews()
    }

    func end() {
        mode = .none
        selected = nil
        rowAnchor = nil
        hintText = nil
        store.flush()
        for w in windows { w.setVisible(false) }
        overlay?.refreshViews()
    }

    static func hint(for mode: Mode) -> String? {
        switch mode {
        case .none: return nil
        case .ornament(let k):
            return "Click to put on a \(Catalogue.title(k).lowercased()), as many as you like, or drag to lay a row. Right-click, press Esc or click Done to stop."
        case .tree: return "Click where the tree goes. Esc cancels."
        case .calendar: return "Click where the countdown calendar goes. Esc cancels."
        case .wreath: return "Click a window, or the desktop, to hang the wreath. Esc cancels."
        case .snowman: return "Drag a snowball onto the desktop or a window's top, then more on top, as many as you like."
        case .snowmanPiece(let k):
            return "Click to put on a \(Catalogue.title(k).lowercased()), as many as you like. Right-click or Esc to stop."
        case .lights: return "Click a window to string the lights along its top. Esc cancels."
        case .edit: return "Click something you've put up to select it, then drag to move it. Right-click anything to take it away."
        }
    }

    var hint: String? {
        hintText ?? Self.hint(for: mode)
    }

    // MARK: hit testing

    func decoration(at point: CGPoint, screen: NSScreen) -> Decoration? {
        let list = store.decorations.filter { $0.screen == NSScreen.screens.firstIndex(of: screen) ?? 0 }
        return list.sorted(by: { $0.z > $1.z }).first { $0.contains(point, in: CGRect(origin: .zero, size: screen.frame.size)) }
    }

    func hitSnowman(at point: CGPoint, screen: NSScreen) -> Decoration? {
        let size = screen.frame.size
        return store.decorations
            .filter { $0.kind == "snowman" && $0.screen == (NSScreen.screens.firstIndex(of: screen) ?? 0) }
            .first { $0.displayRect(in: CGRect(origin: .zero, size: size)).contains(point) }
    }

    // MARK: mouse input

    func mouseDown(at point: CGPoint, screen: NSScreen, event: NSEvent, viewPoint: CGPoint) {
        currentScreen = screen
        let bounds = CGRect(origin: .zero, size: screen.frame.size)
        if hitDone(viewPoint: viewPoint, screen: screen) { end(); return }

        switch mode {
        case .none:
            return
        case .ornament(let kind):
            placeOrnament(kind, at: point, screen: screen, isDrag: false)
            rowAnchor = point
        case .tree:
            placeSingle("tree", at: point, screen: screen, standing: true)
            rowAnchor = point
        case .calendar:
            placeCalendar(at: point, screen: screen)
        case .wreath:
            placeSingle("wreath", at: point, screen: screen, standing: false)
            rowAnchor = point
        case .snowman:
            if let existing = hitSnowman(at: point, screen: screen), existing.id == selected || selected == nil {
                addBall(to: existing)
                selected = existing.id
            } else {
                placeSnowman(at: point, screen: screen)
            }
        case .snowmanPiece(let kind):
            if let sm = hitSnowman(at: point, screen: screen) {
                addPiece(kind, to: sm, at: point, screen: screen)
            } else if let d = decoration(at: point, screen: screen) {
                selected = d.id
            }
        case .lights:
            placeLights(at: point, screen: screen, bounds: bounds)
        case .edit:
            if let d = decoration(at: point, screen: screen) {
                selected = d.id
                dragOrigin = point
                startRect = d.displayRect(in: bounds)
                overlay?.refreshViews()
            } else if let calendar = store.decorations.first(where: {
                $0.kind == "calendar" && $0.screen == (NSScreen.screens.firstIndex(of: screen) ?? 0)
                    && $0.displayRect(in: bounds).contains(point)
            }) {
                openDoor(on: calendar, at: point, screen: screen)
            } else {
                selected = nil
            }
        }
    }

    func mouseDragged(to point: CGPoint, screen: NSScreen, bounds: CGRect) {
        guard let origin = dragOrigin, let id = selected,
              let idx = store.decorations.firstIndex(where: { $0.id == id }) else { return }
        var d = store.decorations[idx]
        d.x += point.x - origin.x
        d.y += point.y - origin.y
        dragOrigin = point
        store.update(d)
        _ = bounds
    }

    func dragStamped(to point: CGPoint, screen: NSScreen) {
        guard let anchor = rowAnchor else { return }
        if hypot(point.x - anchor.x, point.y - anchor.y) > 42 {
            switch mode {
            case .ornament(let kind):
                placeOrnament(kind, at: point, screen: screen, isDrag: true)
                rowAnchor = point
            case .snowman:
                if let last = store.decorations.last(where: { $0.kind == "snowman" }) {
                    addBall(to: last)
                }
                rowAnchor = point
            default:
                break
            }
        }
    }

    func mouseUp() {
        dragOrigin = nil
        rowAnchor = nil
        store.flush()
    }

    func rightClick(at point: CGPoint, screen: NSScreen) {
        if let d = decoration(at: point, screen: screen) {
            store.remove(id: d.id)
            selected = nil
            overlay?.refreshViews()
            return
        }
        if mode != .edit { end() }
    }

    func scroll(delta: CGFloat, screen: NSScreen) {
        guard let id = selected, let idx = store.decorations.firstIndex(where: { $0.id == id })
        else { return }
        var d = store.decorations[idx]
        let factor = 1 + Double(delta) * 0.02
        d.height = max(28, min(1600, d.height * factor))
        if d.kind == "calendar" { d.width = max(150, min(900, d.width * factor)) }
        if d.kind == "snowman" {
            d.radii = d.radii.map { max(4, $0 * factor) }
        }
        store.update(d)
    }

    func rotateSelected(by degrees: Double) {
        guard let id = selected, let idx = store.decorations.firstIndex(where: { $0.id == id })
        else { return }
        var d = store.decorations[idx]
        d.angle += degrees
        store.update(d)
    }

    // MARK: placing

    private func screenIndex(_ screen: NSScreen) -> Int {
        NSScreen.screens.firstIndex(of: screen) ?? 0
    }

    private func placeOrnament(_ kind: String, at point: CGPoint, screen: NSScreen, isDrag: Bool) {
        let bounds = CGRect(origin: .zero, size: screen.frame.size)
        // Hanging an ornament on the tree?
        if let tree = store.decorations.first(where: {
            $0.kind == "tree" && $0.screen == screenIndex(screen)
                && $0.displayRect(in: bounds).insetBy(dx: -10, dy: -10).contains(point)
        }) {
            var t = tree
            let r = tree.displayRect(in: bounds)
            let u = (point.x - r.midX) / (r.width * 0.44)
            let v = (point.y - (r.minY + r.height * 0.20)) / (r.height * 0.36) - 1
            t.props.append(Prop(kind: kind, u: Double(u), v: min(1, max(-1, Double(v))),
                                scale: 1, angle: 0,
                                color: ornamentPalette.randomElement()))
            store.update(t)
            return
        }
        let window = WindowTracker.shared.window(under: point)
        var d = Decoration(kind: "ornament", ornament: kind,
                           x: Double(point.x), y: Double(point.y),
                           screen: screenIndex(screen), height: 54,
                           hang: window == nil ? "free" : "top",
                           seed: UInt64.random(in: 1...99_999),
                           tint: ornamentPalette.randomElement())
        if let w = window {
            d.y = Double(w.maxY - 22)
            d.windowPid = WindowTracker.shared.surfaces().first(where: {
                WindowTracker.cocoaRect($0.rect) == w
            })?.pid
        }
        d.z = isDrag ? 10 : 10
        store.add(d)
    }

    private func placeSingle(_ kind: String, at point: CGPoint, screen: NSScreen, standing: Bool) {
        let bounds = CGRect(origin: .zero, size: screen.frame.size)
        var d = Decoration(kind: kind, x: Double(point.x), y: Double(point.y),
                           screen: screenIndex(screen),
                           height: kind == "tree" ? 340 : 120,
                           hang: standing ? "free" : "top",
                           seed: UInt64(Date().timeIntervalSince1970))
        if standing, let w = WindowTracker.shared.windowTop(near: point) {
            d.y = Double(w.maxY + (kind == "tree" ? 170 : 60))
            d.windowPid = WindowTracker.shared.surfaces().first(where: {
                WindowTracker.cocoaRect($0.rect) == w
            })?.pid
        }
        d.z = 5
        _ = bounds
        store.add(d)
    }

    private func placeCalendar(at point: CGPoint, screen: NSScreen) {
        var d = Decoration(kind: "calendar", x: Double(point.x), y: Double(point.y),
                           screen: screenIndex(screen), height: 246, width: 300,
                           hang: "free", seed: UInt64(Advent.daysSinceEpoch(Date()) % 100_000))
        d.z = 6
        store.add(d)
        hintText = "One more door each day from the day you hang it, and in December, every door up to the date."
    }

    private func placeSnowman(at point: CGPoint, screen: NSScreen) {
        var d = Decoration(kind: "snowman", x: Double(point.x), y: Double(point.y),
                           screen: screenIndex(screen), height: 190,
                           radii: [30, 22, 16], hang: "free",
                           seed: UInt64.random(in: 1...99_999))
        if let w = WindowTracker.shared.windowTop(near: point) {
            d.y = Double(w.maxY) + 30
        } else {
            d.y = Double(point.y) + 30
        }
        d.z = 7
        store.add(d)
        selected = d.id
    }

    private func addBall(to d: Decoration) {
        var s = d
        var radii = s.radii.isEmpty ? [30.0, 22.0, 16.0] : s.radii
        let last = radii.last ?? 16
        radii.append(max(9, last * 0.82))
        s.radii = radii
        s.height = radii.reduce(0, +) * 2.1
        store.update(s)
        selected = s.id
    }

    private func addPiece(_ kind: String, to sm: Decoration, at point: CGPoint, screen: NSScreen) {
        let bounds = CGRect(origin: .zero, size: screen.frame.size)
        let r = sm.displayRect(in: bounds)
        let u = Double((point.x - r.midX) / (r.width * 0.52))
        let v = Double((point.y - r.midY) / (r.height * 0.52))
        let snapScale: Double
        switch kind {
        case "coal": snapScale = 0.55
        case "carrot": snapScale = 1.0
        case "topHat", "beanie", "santaHat": snapScale = 1.0
        default: snapScale = 0.9
        }
        var s = sm
        s.props.append(Prop(kind: kind, u: min(1, max(-1, u)), v: min(1, max(-1, v)),
                            scale: snapScale, angle: 0, color: kind == "scarf" || kind == "topHat"
                            ? "#C71A24" : nil))
        store.update(s)
        selected = s.id
    }

    private func placeLights(at point: CGPoint, screen: NSScreen, bounds: CGRect) {
        let hit = WindowTracker.shared.window(under: point)
        var d = Decoration(kind: "lights", x: Double(point.x), y: Double(point.y),
                           screen: screenIndex(screen), height: 40, hang: "free",
                           seed: UInt64.random(in: 1...9_999))
        if let w = hit {
            let local = CGRect(x: w.minX - screen.frame.minX, y: w.minY - screen.frame.minY,
                               width: w.width, height: w.height)
            d.hang = "top"
            d.x = Double(local.maxX)
            d.y = Double(local.maxY)
            d.width = Double(local.width)
            d.height = Double(local.height)
            d.windowPid = WindowTracker.shared.surfaces().first(where: {
                WindowTracker.cocoaRect($0.rect) == w
            })?.pid
        } else {
            // A tacked string: a lazy catenary across the click point.
            let pts = stride(from: 0.0, through: 1.0, by: 0.125).map { t -> Prop in
                let x = point.x - 140 + 280 * CGFloat(t)
                let y = point.y - sin(Double(t) * .pi) * 26
                return Prop(kind: "bulb", u: Double(x), v: Double(y))
            }
            d.props = pts
            d.hang = "free"
        }
        d.z = 4
        store.add(d)
        _ = bounds
    }

    private func openDoor(on calendar: Decoration, at point: CGPoint, screen: NSScreen) {
        let bounds = CGRect(origin: .zero, size: screen.frame.size)
        let r = calendar.displayRect(in: bounds)
        let relX = (point.x - r.minX) / r.width
        let relY = (point.y - r.minY) / r.height
        let col = Int(relX * 6)
        let row = Int((1 - relY) * 4)
        guard (0..<6).contains(col), (0..<4).contains(row) else { return }
        let day = row * 6 + col + 1
        guard (1...24).contains(day) else { return }
        if store.openedDoors(for: calendar).contains(day) {
            hintText = "\(Advent.surprise(for: day)) — already opened."
            return
        }
        if day > Advent.unlocked(calendar) {
            let sleeps = Advent.sleepsTillChristmas
            hintText = sleeps <= 1 ? "One more sleep till Christmas" : "\(sleeps) sleeps till Christmas"
            return
        }
        store.markDoor(day, on: calendar)
        hintText = Advent.surprise(for: day)
    }

    // MARK: following windows

    /// Keep anything attached to another app's window in step with it.
    func followWindows() {
        let surfaces = WindowTracker.shared.surfaces()
        for d in store.decorations where d.windowPid != nil {
            guard let s = surfaces.first(where: { $0.pid == d.windowPid }),
                  let idx = store.decorations.firstIndex(of: d) else { continue }
            let cocoa = WindowTracker.cocoaRect(s.rect)
            let sc = NSScreen.screens.first { $0.frame.intersects(cocoa) }
                ?? NSScreen.screens[min(d.screen, NSScreen.screens.count - 1)]
            let local = CGRect(x: cocoa.minX - sc.frame.minX, y: cocoa.minY - sc.frame.minY,
                               width: cocoa.width, height: cocoa.height)
            var item = store.decorations[idx]
            switch item.kind {
            case "lights":
                item.x = Double(local.maxX)
                item.y = Double(local.maxY)
                item.width = Double(local.width)
                item.height = Double(local.height)
            default:
                item.x = Double(local.midX)
                if item.hang == "top" { item.y = Double(local.maxY - 22) }
            }
            if item.x != store.decorations[idx].x || item.y != store.decorations[idx].y {
                store.decorations[idx] = item
            }
        }
    }

    private func hitDone(viewPoint: CGPoint, screen: NSScreen) -> Bool {
        let bar = PlacementView.hintBarRect(in: CGRect(origin: .zero, size: screen.frame.size))
        let done = PlacementView.doneRect(in: bar)
        return done.contains(viewPoint)
    }
}

// MARK: - Interactive panel

final class PlacementWindow: NSPanel {
    init(screen: NSScreen, controller: PlacementController) {
        super.init(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        isMovable = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        let view = PlacementView(frame: screen.frame)
        view.screenRef = screen
        view.controller = controller
        contentView = view
        setFrame(screen.frame, display: false)
        alphaValue = 0
        ignoresMouseEvents = true
        orderOut(nil)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func setVisible(_ v: Bool) {
        ignoresMouseEvents = !v
        alphaValue = v ? 1 : 0
        if v {
            orderFrontRegardless()
        } else {
            orderOut(nil)
        }
    }
}

final class PlacementView: NSView {
    var controller: PlacementController?
    var screenRef: NSScreen?
    var selection: UUID?
    var decorations: [Decoration] = []
    private var tracking = false

    override var isOpaque: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext, let c = controller else { return }
        ctx.clear(bounds)
        if c.mode == .none { return }

        // Hint bar
        let bar = Self.hintBarRect(in: bounds)
        if let text = c.hint {
            ctx.setFillColor(NSColor(white: 0.08, alpha: 0.86).cgColor)
            let p = CGPath(roundedRect: bar, cornerWidth: 14, cornerHeight: 14, transform: nil)
            ctx.addPath(p); ctx.fillPath()
            let done = Self.doneRect(in: bar)
            ctx.setFillColor(NSColor(white: 0.98, alpha: 0.96).cgColor)
            ctx.addPath(CGPath(roundedRect: done, cornerWidth: 8, cornerHeight: 8, transform: nil))
            ctx.fillPath()
            let doneText = NSAttributedString(string: "Done", attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: NSColor.black
            ])
            let ds = doneText.size()
            doneText.draw(at: NSPoint(x: done.midX - ds.width / 2, y: done.midY - ds.height / 2))

            let textRect = CGRect(x: bar.minX + 18, y: bar.minY + 10,
                                  width: bar.width - done.width - 48, height: bar.height - 20)
            let para = NSMutableParagraphStyle()
            para.lineBreakMode = .byWordWrapping
            let attr = NSAttributedString(string: text, attributes: [
                .font: NSFont.systemFont(ofSize: 12.5, weight: .medium),
                .foregroundColor: NSColor.white,
                .paragraphStyle: para
            ])
            attr.draw(in: textRect)
        }

        // Selection handles
        for d in decorations where d.id == c.selection {
            let r = d.displayRect(in: bounds)
            ctx.saveGState()
            ctx.setStrokeColor(NSColor.systemGreen.cgColor)
            ctx.setLineWidth(1.5)
            ctx.setLineDash(phase: 0, lengths: [5, 4])
            ctx.stroke(r.insetBy(dx: -4, dy: -4))
            ctx.restoreGState()
            // Resize grip
            let grip = CGRect(x: r.maxX - 7, y: r.minY - 7, width: 14, height: 14)
            ctx.setFillColor(NSColor.systemGreen.cgColor)
            ctx.fillEllipse(in: grip)
            // Rotate handle
            let handle = CGPoint(x: r.midX, y: r.maxY + 26)
            ctx.setStrokeColor(NSColor.systemGreen.withAlphaComponent(0.8).cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: r.midX, y: r.maxY + 4))
            ctx.addLine(to: handle)
            ctx.strokePath()
            ctx.setFillColor(NSColor.systemGreen.cgColor)
            ctx.fillEllipse(in: CGRect(x: handle.x - 6, y: handle.y - 6, width: 12, height: 12))
        }
    }

    static func hintBarRect(in bounds: CGRect) -> CGRect {
        let width = min(760, bounds.width - 80)
        return CGRect(x: bounds.midX - width / 2, y: 34, width: width, height: 62)
    }

    static func doneRect(in bar: CGRect) -> CGRect {
        CGRect(x: bar.maxX - 86, y: bar.midY - 14, width: 70, height: 28)
    }

    private func local(_ e: NSEvent) -> CGPoint {
        convert(e.locationInWindow, from: nil)
    }

    override func mouseDown(with event: NSEvent) {
        let p = local(event)
        guard let screen = screenRef else { return }
        controller?.mouseDown(at: p, screen: screen, event: event, viewPoint: p)
        tracking = true
        needsDisplay = true
        syncDecorations()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let screen = screenRef, tracking else { return }
        let p = local(event)
        controller?.mouseDragged(to: p, screen: screen, bounds: bounds)
        controller?.dragStamped(to: p, screen: screen)
        needsDisplay = true
        syncDecorations()
    }

    override func mouseUp(with event: NSEvent) {
        tracking = false
        controller?.mouseUp()
        syncDecorations()
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let screen = screenRef else { return }
        controller?.rightClick(at: local(event), screen: screen)
        syncDecorations()
    }

    override func scrollWheel(with event: NSEvent) {
        guard let screen = screenRef else { return }
        controller?.scroll(delta: event.scrollingDeltaY, screen: screen)
        if event.modifierFlags.contains(.option) {
            controller?.rotateSelected(by: event.scrollingDeltaY > 0 ? 4 : -4)
        }
        needsDisplay = true
        syncDecorations()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { controller?.end() }
        needsDisplay = true
    }

    private func syncDecorations() {
        decorations = TinselStore.shared.decorations
        needsDisplay = true
    }

    override func viewDidMoveToWindow() {
        window?.makeFirstResponder(self)
    }
}
