#!/bin/bash

set -e

APP_DIR="dist/macos/FocusMonitorSwitch.app"
DMG_PATH="dist/macos/FocusMonitorSwitch.dmg"
DMG_DIR="dist/macos/dmg"

CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
HELPERS_DIR="$CONTENTS_DIR/Helpers"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR" "$DMG_PATH" "$DMG_DIR"
mkdir -p "$MACOS_DIR" "$HELPERS_DIR" "$RESOURCES_DIR"

GOOS=darwin go build -o "$HELPERS_DIR/FocusMonitorSwitch" .
cp AppIcon.png "$RESOURCES_DIR/AppIcon.png"

cat > "$MACOS_DIR/FocusMonitorSwitchLauncher" <<'EOF'
#!/bin/bash

set -e

BINARY_PATH="${0%/*}/../Helpers/FocusMonitorSwitch"
PLIST_PATH="$HOME/Library/LaunchAgents/com.nielsprins.focusmonitorswtich.plist"

mkdir -p "${PLIST_PATH%/*}"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.nielsprins.focusmonitorswtich</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BINARY_PATH</string>
  </array>
  <key>KeepAlive</key>
  <true/>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST

launchctl bootout "gui/$UID/com.nielsprins.focusmonitorswtich" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST_PATH"
EOF

cat > "$CONTENTS_DIR/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>FocusMonitorSwitchLauncher</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.png</string>
  <key>CFBundleIdentifier</key>
  <string>com.nielsprins.focusmonitorswtich</string>
  <key>CFBundleName</key>
  <string>FocusMonitorSwitch</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF

chmod +x "$MACOS_DIR/FocusMonitorSwitchLauncher" "$HELPERS_DIR/FocusMonitorSwitch"

mkdir -p "$DMG_DIR"
cp -R "$APP_DIR" "$DMG_DIR/FocusMonitorSwitch.app"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create \
  -volname "FocusMonitorSwitch" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

printf "Built:\n  %s\n  %s\n" "$APP_DIR" "$DMG_PATH"
