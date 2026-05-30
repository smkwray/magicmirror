#!/bin/zsh
set -euo pipefail

INSTALL_DIR="$HOME/.hammerspoon/trackpad-orientation"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.smkwray.magicmirror.plist"

# Stop the watch daemon first so it does not re-apply while we reset.
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true

# Reset every external trackpad to normal (works regardless of USB/Bluetooth).
if [[ -x "$INSTALL_DIR/mt-orient" ]]; then
  "$INSTALL_DIR/mt-orient" reset || true
elif [[ -x "$INSTALL_DIR/mt-orientation" ]]; then
  "$INSTALL_DIR/mt-orientation" normal || true
fi

rm -f "$LAUNCH_AGENT"
rm -rf "$INSTALL_DIR"

echo "MagicMirror removed and trackpads reset to normal."
