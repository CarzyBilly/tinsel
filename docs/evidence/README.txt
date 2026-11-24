Evidence collected from the shipped reference app
==================================================

Target
------
/Applications/Deck the Desktop.app
  CFBundleIdentifier       com.mikefifield.snow.mas
  CFBundleShortVersion    1.0        (CFBundleVersion 202610230902)
  LSMinimumSystemVersion  14.0
  LSUIElement             true
  Executable              Mach-O universal (x86_64 + arm64), 2,508,144 bytes
                          sha256 677deb07bf26fb9de1fdcfab66797919bf9e2bd84549dea34c5ef4cd73a638c7
  Resources               139 files: 31 full wallpapers, 31 thumbnails,
                          8 wallpaper masks, 20 ornament PNGs, 19 snowman PNGs,
                          9 banner JPEGs, tree.png, wreath.png, Assets.car,
                          AppIcon.icns, PrivacyInfo.xcprivacy
  Linked frameworks       Foundation, AppKit, SwiftUI, Combine, CoreGraphics,
                          CoreText, QuartzCore, IOKit, ServiceManagement,
                          QuickLookThumbnailing

Commands used (read-only; nothing was modified, patched or executed as code)
----------------------------------------------------------------------------
  file "Contents/MacOS/Deck the Desktop"
  lipo -info "Contents/MacOS/Deck the Desktop"
  otool -L "Contents/MacOS/Deck the Desktop"
  plutil -p Contents/Info.plist
  strings -a -n 3 "Contents/MacOS/Deck the Desktop" > binary-strings-raw.txt
  # filtered to user-facing text -> binary-ui-strings.txt
  plutil -p ~/Library/Containers/com.mikefifield.snow.mas/Data/Library/Preferences/com.mikefifield.snow.mas.plist
  screencapture -x -o -l <settings window id> original-settings-snowmen.png
  # window geometry via CGWindowListCopyWindowInfo (see below)

Window geometry while running
-----------------------------
pid=2385 win=679 layer=19  1920x1080 @ 0,0        (front snow layer, display 1)
pid=2385 win=678 layer=18  1920x1080 @ 0,0        (back layer, display 1)
pid=2385 win=677 layer=19   756x1344 @ -756,0     (front snow layer, display 2)
pid=2385 win=676 layer=18   756x1344 @ -756,0     (back layer, display 2)
pid=2385 win=426 layer=0    880x700               "Deck the Desktop Settings"

Saved decoration record (from the preferences dump), illustrating the model
--------------------------------------------------------------------------
{
  "kind": "snowman", "x": 283.44921875, "height": 0, "hang": "top",
  "radii": [24, 18, 13], "seed": 166963171,
  "props": [
    {"kind": "topHat", "u": 0, "v": 1.35, "scale": 1, "angle": 0, "anchor": 2, "color": "#C71A24"},
    {"kind": "scarf",  "u": 0.05, "v": -1.466630063965885, "scale": 1, "angle": 0, "anchor": 2, "color": "#C71A24"},
    {"kind": "coal",   "u": -0.34, "v": 0.24, "scale": 1, "angle": -1, "anchor": 2},
    ...
  ]
}
Top-level preference keys seen: decorations, settingsPane, clearActiveWindow,
clearAllWindows, "NSWindow Frame SnowSettings".

Limits of this evidence
-----------------------
* The binary is stripped, so function-level behaviour was inferred from
  user-facing strings, Swift type metadata and the persisted data model, not
  from reading decompiled code.
* The app was observed running (screenshot and window list) but not driven
  through every pane; pane contents beyond the one captured were reconstructed
  from the string inventory.
* No asset, string table, icon, or code from the target is redistributed here;
  binary-strings-raw.txt is included only as the observation record.
