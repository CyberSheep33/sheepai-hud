#!/bin/bash
set -euo pipefail

APP_PATH="${CODESIGNING_FOLDER_PATH:-${BUILT_PRODUCTS_DIR:-$1}}"
if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    exit 0
fi

WIDGET_PLIST="${SRCROOT:-$PROJECT_DIR}/Widgets/Info.plist"
TARGET_PLIST="$APP_PATH/Contents/PlugIns/Widgets.appex/Contents/Info.plist"

if [ -f "$WIDGET_PLIST" ] && [ -f "$TARGET_PLIST" ]; then
    cp "$WIDGET_PLIST" "$TARGET_PLIST"
    echo "Patched Widgets Info.plist with NSExtension"
fi

cp -R "$APP_PATH" /Applications/SheepAI.app 2>/dev/null && echo "Copied to /Applications" || true
