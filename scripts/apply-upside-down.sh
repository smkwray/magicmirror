#!/bin/zsh
set -euo pipefail

"$HOME/.hammerspoon/trackpad-orientation/mt-orientation" upside-down >/tmp/trackpad-orientation.log 2>&1
printf 'upside-down\n' > "$HOME/.hammerspoon/trackpad-orientation/state"

osascript -e 'display notification "Magic Trackpad: upside down" with title "Trackpad orientation"' >/dev/null 2>&1 || true
