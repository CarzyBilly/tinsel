import AppKit
import ApplicationServices

// MARK: - Other apps' windows

struct Surface {
    var rect: CGRect       // Accessibility coordinates: y down from the top of the primary display
    var pid: pid_t
    var index: Int
    var title: String
    var appName: String
}

/// Reads the on-screen windows of other apps so snow can settle on their tops,
/// icicles can hang from them and light strings can follow them around.
@MainActor
final class WindowTracker {
    static let shared = WindowTracker()

    private var cached: [Surface] = []
    private var cachedAt: CFTimeInterval = 0
    private var previousRects: [pid_t: CGRect] = [:]
    var onShake: ((CGRect) -> Void)?
    var shakeToClear = true

    private var trusted: Bool { AXIsProcessTrusted() }

    static func requestAccess() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static var hasAccess: Bool { AXIsProcessTrusted() }

    /// Convert an Accessibility rect into Cocoa global screen coordinates.
    static func cocoaRect(_ r: CGRect) -> CGRect {
        let top = NSScreen.screens.first?.frame.maxY ?? 0
        return CGRect(x: r.minX, y: top - r.maxY, width: r.width, height: r.height)
    }

    static func axRect(_ cocoa: CGRect) -> CGRect {
        let top = NSScreen.screens.first?.frame.maxY ?? 0
        return CGRect(x: cocoa.minX, y: top - cocoa.maxY, width: cocoa.width, height: cocoa.height)
    }

    func surfaces(force: Bool = false) -> [Surface] {
        let now = CACurrentMediaTime()
        if !force && now - cachedAt < 0.7 { return cached }
        cachedAt = now
        guard trusted else { cached = []; return [] }
        var result: [Surface] = []
        let ownPid = ProcessInfo.processInfo.processIdentifier
        for app in NSWorkspace.shared.runningApplications where !app.isTerminated {
            if app.processIdentifier == ownPid { continue }
            if app.bundleIdentifier == "com.apple.dock" ||
                app.bundleIdentifier == "com.apple.controlcenter" { continue }
            let element = AXUIElementCreateApplication(app.processIdentifier)
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &value) == .success,
                  let windows = value as? [AXUIElement] else { continue }
            for (i, win) in windows.enumerated() {
                if let rect = Self.frame(of: win) {
                    let surface = Surface(rect: rect, pid: app.processIdentifier, index: i,
                                          title: Self.title(of: win) ?? "",
                                          appName: app.localizedName ?? "")
                    result.append(surface)
                }
            }
        }
        // Shake detection: a window that moved a lot clears the snow on it.
        if shakeToClear {
            for s in result {
                if let old = previousRects[s.pid], old != s.rect {
                    let moved = hypot(old.midX - s.rect.midX, old.midY - s.rect.midY)
                    if moved > 26 {
                        onShake?(Self.cocoaRect(s.rect))
                    }
                }
            }
        }
        var map: [pid_t: CGRect] = [:]
        for s in result { map[s.pid] = s.rect }
        previousRects = map
        cached = result
        return result
    }

    private static func frame(of win: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeRef) == .success
        else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        guard size.width > 40, size.height > 40 else { return nil }
        return CGRect(origin: point, size: size)
    }

    private static func title(of win: AXUIElement) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(win, kAXTitleAttribute as CFString, &ref) == .success
        else { return nil }
        return ref as? String
    }

    /// The window whose top edge is closest to a point on screen, if it is near.
    func windowTop(near cocoaPoint: CGPoint) -> CGRect? {
        var best: CGRect?
        var bestDistance = 34.0
        for s in surfaces() {
            let r = Self.cocoaRect(s.rect)
            guard cocoaPoint.x >= r.minX - 20, cocoaPoint.x <= r.maxX + 20 else { continue }
            let d = abs(r.maxY - cocoaPoint.y)
            if d < bestDistance {
                bestDistance = d
                best = r
            }
        }
        return best
    }

    func window(under cocoaPoint: CGPoint) -> CGRect? {
        for s in surfaces() {
            let r = Self.cocoaRect(s.rect)
            if r.contains(cocoaPoint) { return r }
        }
        return nil
    }
}

// MARK: - Advent calendar rules

enum Advent {
    static var today: Int {
        let cal = Calendar.current
        let now = Date()
        let month = cal.component(.month, from: now)
        return month == 12 ? cal.component(.day, from: now) : 0
    }

    static var isDecember: Bool { Calendar.current.component(.month, from: Date()) == 12 }

    static func daysSinceEpoch(_ date: Date) -> UInt64 {
        UInt64(max(0, Calendar.current.startOfDay(for: date).timeIntervalSince1970 / 86_400))
    }

    static func installedDay(_ d: Decoration) -> Int {
        Int(d.seed % 100_000)
    }

    /// The highest door that may be opened right now.
    static func unlocked(_ d: Decoration) -> Int {
        let cal = Calendar.current
        if isDecember {
            return min(24, cal.component(.day, from: Date()))
        }
        let installed = installedDay(d)
        let now = Int(daysSinceEpoch(Date()) % 100_000)
        return min(24, max(1, now - installed + 1))
    }

    static var sleepsTillChristmas: Int {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        var year = cal.component(.year, from: now)
        if cal.component(.month, from: now) == 12 && cal.component(.day, from: now) > 25 { year += 1 }
        var comps = DateComponents()
        comps.year = year
        comps.month = 12
        comps.day = 25
        guard let xmas = cal.date(from: comps) else { return 0 }
        return max(0, cal.dateComponents([.day], from: now, to: xmas).day ?? 0)
    }

    static func surprise(for day: Int) -> String {
        switch day {
        case 24: return "Christmas Eve"
        case 25: return "Merry Christmas!"
        default: return "A little something"
        }
    }
}
