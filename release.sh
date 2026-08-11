#!/bin/bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version> (e.g., ./release.sh 1.0.0)"
    exit 1
fi

APP_NAME="CreateVideo"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MAC_OS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
DMG_STAGING="dmg_staging"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"

echo "⏳ Compilation du projet en mode Release..."
swift build -c release

echo "📦 Création du bundle macOS (.app)..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MAC_OS"
mkdir -p "$RESOURCES"

cp "${BUILD_DIR}/App" "$MAC_OS/${APP_NAME}"

if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

cat > "$CONTENTS/Info.plist" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.projectbuilder.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

echo "💿 Création de l'image disque (DMG)..."
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

rm -f "$DMG_NAME"
hdiutil create -volname "${APP_NAME} ${VERSION}" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_NAME"

echo "🧹 Nettoyage..."
rm -rf "$DMG_STAGING"
rm -rf "$APP_BUNDLE"

echo "✅ Succès ! Le fichier $DMG_NAME a été généré."
