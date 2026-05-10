#!/bin/zsh
set -euo pipefail

state="$(cat "$HOME/.hammerspoon/trackpad-orientation/state" 2>/dev/null || echo upside-down)"

if [[ "$state" == "normal" ]]; then
  "$HOME/.hammerspoon/trackpad-orientation/mt-orientation" normal >/tmp/trackpad-orientation.log 2>&1
else
  "$HOME/.hammerspoon/trackpad-orientation/mt-orientation" upside-down >/tmp/trackpad-orientation.log 2>&1
fi

