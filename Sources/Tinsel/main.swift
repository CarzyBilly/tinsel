import AppKit

// Tinsel — deck your desktop. A menu-bar app that snows behind (and above)
// your windows, strings lights, hangs ornaments, builds snowmen and opens an
// advent calendar. Written from scratch; no third-party code.

// Offscreen modes used by the build script: artwork samples and self-checks.
if Diagnostics.run() {
    exit(0)
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let appDelegate = AppDelegate()
    app.delegate = appDelegate
    app.setActivationPolicy(.accessory)
    app.run()
}
