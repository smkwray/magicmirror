#!/bin/zsh
set -euo pipefail

"$HOME/.hammerspoon/trackpad-orientation/mt-orientation" normal >/tmp/trackpad-orientation.log 2>&1
printf 'normal\n' > "$HOME/.hammerspoon/trackpad-orientation/state"
