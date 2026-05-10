#!/bin/zsh
set -euo pipefail

INSTALL_DIR="$HOME/.hammerspoon/trackpad-orientation"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.smkwray.magicmirror.plist"

if [[ -x "$INSTALL_DIR/mt-orientation" ]]; then
  "$INSTALL_DIR/mt-orientation" normal || true
fi

launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
rm -f "$LAUNCH_AGENT"
rm -rf "$INSTALL_DIR"

echo "MagicMirror removed and trackpad orientation reset to normal."
