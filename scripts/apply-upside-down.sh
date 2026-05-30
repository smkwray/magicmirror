#!/bin/zsh
# apply-upside-down.sh [product-id]
# Force a specific trackpad model upside-down (default: toggle-target, else 613).
set -euo pipefail

DIR="$HOME/.hammerspoon/trackpad-orientation"
target="${1:-$(awk '/^toggle-target[[:space:]]/{print $2; exit}' "$DIR/orient.conf" 2>/dev/null || true)}"
target="${target:-613}"
"$DIR/set-orientation.sh" "$target" upside-down
