#!/bin/zsh
set -euo pipefail

"$HOME/.hammerspoon/trackpad-orientation/mt-orientation" normal >/tmp/trackpad-orientation.log 2>&1
printf 'normal\n' > "$HOME/.hammerspoon/trackpad-orientation/state"

osascript -e 'display notification "Magic Trackpad: normal" with title "Trackpad orientation"' >/dev/null 2>&1 || true
