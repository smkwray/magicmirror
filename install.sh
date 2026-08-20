#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.hammerspoon/trackpad-orientation"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.smkwray.magicmirror.plist"

mkdir -p "$INSTALL_DIR" "$HOME/Library/LaunchAgents"

# Durable, ProductID-keyed manager + daemon (handles per-device, USB/BT, reconnect).
clang -fobjc-arc -framework Foundation -framework IOKit \
  "$ROOT_DIR/src/mt-orient.m" \
  -o "$INSTALL_DIR/mt-orient"

# Legacy all-Bluetooth helper kept for reference/compatibility.
clang -fobjc-arc -framework Foundation \
  "$ROOT_DIR/src/mt-orientation.m" \
  -o "$INSTALL_DIR/mt-orientation"

cp "$ROOT_DIR/scripts/"*.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/"*.sh "$INSTALL_DIR/mt-orient" "$INSTALL_DIR/mt-orientation"

# Seed a policy-neutral config only if absent. The installer must not impose the
# maintainer's ProductIDs or flip a stranger's hardware merely by being installed.
if [[ ! -f "$INSTALL_DIR/orient.conf" ]]; then
  cat > "$INSTALL_DIR/orient.conf" <<'CONF'
# Durable orientation keyed by ProductID (a model id, not a unique unit id).
# Run `mt-orient list`, then add only the policy you intend, for example:
# product 804 normal
# product 613 upside-down
# toggle-target 613
# Devices whose ProductID is not listed are left untouched.
CONF
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
        <string>$INSTALL_DIR/mt-orient</string>
        <string>watch</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>ProcessType</key>
    <string>Background</string>
    <key>StandardOutPath</key>
    <string>/tmp/magicmirror.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/magicmirror.err.log</string>
</dict>
</plist>
PLIST

plutil -lint "$LAUNCH_AGENT"
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"
launchctl kickstart -k "gui/$(id -u)/com.smkwray.magicmirror"

echo "MagicMirror installed at $INSTALL_DIR"
echo "Config:"
sed 's/^/  /' "$INSTALL_DIR/orient.conf"
echo "Daemon:"
launchctl list | grep com.smkwray.magicmirror | sed 's/^/  /' || echo "  (not running)"
