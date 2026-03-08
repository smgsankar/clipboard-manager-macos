#!/bin/bash

set -e

APP_NAME="ClipboardManager"
BUNDLE_ID="com.smgsankar.ClipboardManager"
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ICON_SOURCE="$PROJECT_ROOT/Resources/icon.png"

echo "Building release binary..."
swift build -c release

echo "Creating app bundle structure..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"

echo "Copying executable..."
cp .build/release/$APP_NAME "$APP_NAME.app/Contents/MacOS/"

echo "Generating app icon..."
if [ -f "$ICON_SOURCE" ]; then
    "$SCRIPT_DIR/generate_icns.sh" "$ICON_SOURCE" "$APP_NAME.app/Contents/Resources" "AppIcon"
    echo "Icon generated successfully"
else
    echo "Warning: Icon source not found at $ICON_SOURCE"
fi

echo "Creating Info.plist..."
cat > "$APP_NAME.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

echo "Signing app bundle..."
# Use ad-hoc signing if no identity is specified
SIGNING_IDENTITY="${CODESIGN_IDENTITY:--}"

if [ "$SIGNING_IDENTITY" = "-" ]; then
    echo "Using ad-hoc signing (for local development only)"
else
    echo "Using signing identity: $SIGNING_IDENTITY"
fi

codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_NAME.app/Contents/MacOS/$APP_NAME"
codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_NAME.app"

echo "Verifying signature..."
codesign --verify --verbose "$APP_NAME.app"

echo ""
echo "✅ App bundle created successfully: $APP_NAME.app"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Version: $VERSION"
echo "   Signing: $([ "$SIGNING_IDENTITY" = "-" ] && echo "Ad-hoc (local only)" || echo "$SIGNING_IDENTITY")"
