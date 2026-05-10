#!/bin/zsh
set -euo pipefail

"$HOME/.hammerspoon/trackpad-orientation/mt-orientation" upside-down >/tmp/trackpad-orientation.log 2>&1
printf 'upside-down\n' > "$HOME/.hammerspoon/trackpad-orientation/state"
