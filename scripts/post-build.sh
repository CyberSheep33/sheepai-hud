#!/bin/bash
# Post-build script for SheepAI HUD
# Fixes Widget NSExtension registration and copies to /Applications
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Find the latest SheepAI.app in DerivedData
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/SheepAI-*/Build/Products/Debug -name "SheepAI.app" -maxdepth 1 2>/dev/null | head -1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Could not find SheepAI.app in DerivedData. Build first with ⌘R in Xcode."
    exit 1
fi

echo "Found: $APP_PATH"

# Patch widget Info.plist with NSExtension registration
WIDGET_PLIST="$PROJECT_DIR/Widgets/Info.plist"
TARGET_PLIST="$APP_PATH/Contents/PlugIns/Widgets.appex/Contents/Info.plist"

if [ -f "$WIDGET_PLIST" ] && [ -f "$TARGET_PLIST" ]; then
    cp "$WIDGET_PLIST" "$TARGET_PLIST"
    echo "✅ Patched Widgets Info.plist with NSExtension"
else
    echo "❌ Could not find Widgets/Info.plist or target plist"
    exit 1
fi

# Copy to /Applications
cp -R "$APP_PATH" /Applications/
echo "✅ Copied to /Applications/SheepAI.app"

# Restart services
killall Dock 2>/dev/null || true
killall NotificationCenter 2>/dev/null || true
echo "✅ Restarted Dock and Notification Center"
echo ""
echo "Done! You can now:"
echo "  1. Launch from Spotlight (⌘Space → SheepAI)"
echo "  2. Add widgets in Notification Center (search 'SheepAI')"
