import AppKit
import SwiftUI

// MARK: - App delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = TinselStore.shared
    lazy var overlay = OverlayController()
    lazy var placement = PlacementController()
    lazy var status = StatusItemController()
    lazy var settingsWindow = SettingsWindowController()
    lazy var saver = SaverController()
    private var followTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay.placement = placement
        placement.overlay = overlay
        overlay.start(store: store, placement: placement)
        placement.install()
        status.install()
        saver.attach(overlay: overlay, store: store)

        WindowTracker.shared.shakeToClear = store.settings.shakeToClear
        WindowTracker.shared.onShake = { [weak self] rect in
            self?.overlay.shake(at: rect)
        }
        _ = WindowTracker.requestAccess()

        if CommandLine.arguments.contains("--demo") { Demo.populate(store) }
        if CommandLine.arguments.contains("--clear") { store.removeAll() }

        followTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.placement.followWindows()
                self?.overlay.refreshViews()
            }
        }
        if let t = followTimer { RunLoop.main.add(t, forMode: .common) }

        // Show the settings window the first time, and whenever asked to.
        let firstRun = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if firstRun { UserDefaults.standard.set(true, forKey: "hasLaunchedBefore") }
        if firstRun || CommandLine.arguments.contains("--settings") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.settingsWindow.show(pane: firstRun ? "saved" : self?.store.pane ?? "saved")
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.flush()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow.show(pane: store.pane)
        return true
    }
}

// MARK: - Menu bar

@MainActor
final class StatusItemController {
    private var item: NSStatusItem?
    private let store = TinselStore.shared
    private weak var appDelegate: AppDelegate?

    func install() {
        appDelegate = NSApp.delegate as? AppDelegate
        if store.settings.showMenuBarIcon {
            addItem()
        }
    }

    func setVisible(_ visible: Bool) {
        if visible && item == nil { addItem() }
        if !visible, let i = item { NSStatusBar.system.removeStatusItem(i); item = nil }
    }

    private func addItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "snowflake", accessibilityDescription: "Tinsel")
        item.button?.image?.isTemplate = true
        item.menu = buildMenu()
        self.item = item
    }

    func refresh() {
        item?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let snow = NSMenuItem(title: store.snowing ? "Stop Snowing" : "Let It Snow",
                              action: #selector(toggleSnowing), keyEquivalent: "s")
        snow.target = self
        menu.addItem(snow)

        let clear = NSMenuItem(title: "Clear Snow", action: #selector(clearSnow), keyEquivalent: "")
        clear.target = self
        menu.addItem(clear)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())

        let decorTitle = store.decorationsShown ? "Put Away Decorations" : "Bring Back Decorations"
        let decor = NSMenuItem(title: decorTitle, action: #selector(toggleDecorations), keyEquivalent: "")
        decor.target = self
        menu.addItem(decor)

        let makeOne = NSMenuItem(title: "Put Up Something…", action: #selector(openDecorate), keyEquivalent: "")
        makeOne.target = self
        menu.addItem(makeOne)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Tinsel", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    @objc private func toggleSnowing() {
        store.snowing.toggle()
        refresh()
    }

    @objc private func clearSnow() {
        appDelegate?.overlay.clearSnow()
    }

    @objc private func openSettings() {
        appDelegate?.settingsWindow.show(pane: store.pane)
    }

    @objc private func toggleDecorations() {
        store.decorationsShown.toggle()
        refresh()
    }

    @objc private func openDecorate() {
        appDelegate?.settingsWindow.show(pane: "decorations")
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - Screen saver snow

@MainActor
final class SaverController {
    private var timer: Timer?
    private weak var overlay: OverlayController?
    private var store: TinselStore?
    private(set) var active = false

    func attach(overlay: OverlayController, store: TinselStore) {
        self.overlay = overlay
        self.store = store
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if let t = timer { RunLoop.main.add(t, forMode: .common) }
    }

    /// Seconds since the last keyboard or mouse event anywhere on the system.
    static func idleTime() -> TimeInterval {
        if let type = CGEventType(rawValue: UInt32.max) {
            return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: type)
        }
        return 0
    }

    private func tick() {
        guard let store, let overlay else { return }
        guard let after = store.settings.saverAfter.seconds else { return }
        let idle = Self.idleTime()
        if !active && idle > after {
            active = true
            var settings = store.settings
            settings.amount = .blizzard
            settings.pace = .slowly
            overlay.saverGlow = store.settings.darkenScreen
            overlay.update(settings: settings)
        } else if active && idle < 2 {
            active = false
            overlay.saverGlow = false
            overlay.update(settings: store.settings)
            if store.settings.saverReturn == .melt {
                overlay.clearSnow()
            }
        }
    }
}

// MARK: - Desktop pictures

enum WallpaperManager {
    static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Tinsel/Wallpapers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func renderedURL(_ spec: SceneSpec, size: CGSize) -> URL? {
        let key = spec.name.replacingOccurrences(of: " ", with: "-")
        let file = folder.appendingPathComponent("\(key)-\(Int(size.width))x\(Int(size.height)).png")
        if FileManager.default.fileExists(atPath: file.path) { return file }
        let pixel = CGSize(width: size.width * 2, height: size.height * 2)
        guard let ctx = CGContext(data: nil, width: Int(pixel.width), height: Int(pixel.height),
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ScenePainter.paint(spec, size: pixel, context: ctx)
        guard let image = ctx.makeImage() else { return nil }
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return nil }
        do {
            try data.write(to: file)
            return file
        } catch {
            NSLog("Tinsel: couldn't write wallpaper: \(error)")
            return nil
        }
    }

    @discardableResult
    static func apply(_ spec: SceneSpec) -> Bool {
        var ok = true
        for screen in NSScreen.screens {
            guard let url = renderedURL(spec, size: screen.frame.size) else { ok = false; continue }
            do {
                try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
            } catch {
                NSLog("Tinsel: couldn't set the desktop picture: \(error)")
                ok = false
            }
        }
        return ok
    }

    static func preview(_ spec: SceneSpec, size: CGSize) -> NSImage {
        ScenePainter.image(spec, pixelSize: CGSize(width: size.width * 2, height: size.height * 2))
    }
}
