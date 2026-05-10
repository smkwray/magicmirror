#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.hammerspoon/trackpad-orientation"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.smkwray.magicmirror.plist"

mkdir -p "$INSTALL_DIR" "$HOME/Library/LaunchAgents"

clang -fobjc-arc -framework Foundation \
  "$ROOT_DIR/src/mt-orientation.m" \
  -o "$INSTALL_DIR/mt-orientation"

cp "$ROOT_DIR/scripts/"*.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/"*.sh "$INSTALL_DIR/mt-orientation"

if [[ ! -f "$INSTALL_DIR/state" ]]; then
  printf 'upside-down\n' > "$INSTALL_DIR/state"
fi

cat > "$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.smkwray.magicmirror</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/apply-current.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/trackpad-orientation-launchd.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/trackpad-orientation-launchd.err</string>
</dict>
</plist>
PLIST

plutil -lint "$LAUNCH_AGENT"
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"
launchctl kickstart -k "gui/$(id -u)/com.smkwray.magicmirror"

echo "MagicMirror installed at $INSTALL_DIR"
echo "Current state: $(cat "$INSTALL_DIR/state")"
