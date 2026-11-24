#!/bin/bash
# Build Tinsel.app into dist/. Pass --verify to run the self-checks first.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG=release
APP="dist/Tinsel.app"
NAME="Tinsel"

if [[ "${1:-}" == "--verify" ]]; then
  swift build -c "$CONFIG" --disable-sandbox --cache-path .cache --scratch-path .build
  .build/$CONFIG/Tinsel --selftest
fi

swift build -c "$CONFIG" --disable-sandbox --cache-path .cache --scratch-path .build
BIN="$(swift build -c "$CONFIG" --disable-sandbox --cache-path .cache --scratch-path .build --show-bin-path)/$NAME"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Icon: render a 1024 pt master, then build the .icns set.
mkdir -p dist/icon.iconset
.build/$CONFIG/Tinsel --render-icon dist/icon-1024.png >/dev/null
for size in 16 32 64 128 256 512; do
  sips -z $size $size dist/icon-1024.png --out "dist/icon.iconset/icon_${size}x${size}.png" >/dev/null
  dbl=$((size * 2))
  sips -z $dbl $dbl dist/icon-1024.png --out "dist/icon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns dist/icon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf dist/icon.iconset dist/icon-1024.png

cp "$BIN" "$APP/Contents/MacOS/$NAME"
chmod +x "$APP/Contents/MacOS/$NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleDisplayName</key><string>Tinsel</string>
  <key>CFBundleExecutable</key><string>Tinsel</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>com.carzybilly.tinsel</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Tinsel</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.entertainment</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>MIT licensed. Built with AppKit and SwiftUI.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>Tinsel reads window positions so snow can settle on window tops and lights can follow a window.</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1 || echo "warning: codesign skipped"
echo "built $APP"
du -sh "$APP"
