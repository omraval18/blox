#!/usr/bin/env bash
# Builds dist/Blox.app (menu bar agent + bundled CLI), dist/Blox-<version>.zip and dist/Blox-<version>.dmg.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(tr -d '[:space:]' < VERSION)
grep -q "bloxVersion = \"$version\"" Sources/BloxIPC/Version.swift \
    || { echo "VERSION ($version) and Sources/BloxIPC/Version.swift disagree"; exit 1; }

swift build -c release
app=dist/Blox.app
rm -rf dist && mkdir -p "$app/Contents/MacOS" "$app/Contents/Helpers"
strip -x -o "$app/Contents/MacOS/Blox" .build/release/BloxApp
strip -x -o "$app/Contents/Helpers/blox" .build/release/blox

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleIdentifier</key><string>dev.blox.Blox</string>
    <key>CFBundleName</key><string>Blox</string>
    <key>CFBundleExecutable</key><string>Blox</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$version</string>
    <key>CFBundleVersion</key><string>$version</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHumanReadableCopyright</key><string>MIT License</string>
</dict></plist>
PLIST

codesign --force --sign - "$app"
codesign --verify --strict "$app"
ditto -c -k --keepParent "$app" "dist/Blox-$version.zip"

stage=$(mktemp -d)
cp -R "$app" "$stage/" && ln -s /Applications "$stage/Applications"
hdiutil create -quiet -volname "Blox $version" -srcfolder "$stage" -ov -format UDZO "dist/Blox-$version.dmg"
rm -rf "$stage"

(cd dist && shasum -a 256 "Blox-$version.zip" "Blox-$version.dmg" > "Blox-$version.sha256")
echo "built dist/Blox-$version.zip and .dmg ($(stat -f %z "dist/Blox-$version.dmg") bytes)"
