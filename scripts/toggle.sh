#!/bin/zsh
set -euo pipefail

state="$(cat "$HOME/.hammerspoon/trackpad-orientation/state" 2>/dev/null || echo normal)"

if [[ "$state" == "upside-down" ]]; then
  "$HOME/.hammerspoon/trackpad-orientation/apply-normal.sh"
else
  "$HOME/.hammerspoon/trackpad-orientation/apply-upside-down.sh"
fi
