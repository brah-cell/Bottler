#!/bin/bash
# Builds Bottler and packages it into a double-clickable Bottler.app
# bundle you can drag into /Applications.
#
# Requirements: Xcode Command Line Tools (for `swift`). Install with:
#   xcode-select --install
#
# Usage:
#   chmod +x build_app.sh
#   ./build_app.sh

set -euo pipefail

APP_NAME="Bottler"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
BUNDLE_ID="com.example.bottler"

echo "==> Building release binary…"
swift build -c release

echo "==> Assembling ${APP_BUNDLE}…"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

if [ -d "Resources/AppIcon.iconset" ]; then
    echo "==> Building app icon…"
    iconutil -c icns "Resources/AppIcon.iconset" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

cat > "${APP_BUNDLE}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1.1.3</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.3</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Bottler opens Terminal to run the Homebrew installer on your behalf when setting up Wine.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc signing (so Gatekeeper doesn't flag it as unsigned)…"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo ""
echo "Done. Drag ${APP_BUNDLE} to /Applications, or run:"
echo "  mv \"${APP_BUNDLE}\" /Applications/"
echo ""
echo "Note: since this isn't signed with a real Developer ID, the first"
echo "launch may need right-click → Open (to bypass Gatekeeper's 'unidentified"
echo "developer' warning) instead of a normal double-click."
