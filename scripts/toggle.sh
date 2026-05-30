#!/bin/zsh
# toggle.sh [product-id]
#
# Toggles one trackpad (by ProductID) between normal and upside-down.
# Target defaults to the `toggle-target` line in orient.conf, else 613
# (Magic Trackpad 2). Bound to Hyper + ' via Karabiner.
set -euo pipefail

DIR="$HOME/.hammerspoon/trackpad-orientation"
CONF="$DIR/orient.conf"

target="${1:-}"
if [[ -z "$target" ]]; then
  target="$(awk '/^toggle-target[[:space:]]/{print $2; exit}' "$CONF" 2>/dev/null || true)"
fi
target="${target:-613}"

cur="$(awk -v p="$target" '$1=="product" && $2==p {print $3; exit}' "$CONF" 2>/dev/null || true)"
if [[ "$cur" == "upside-down" ]]; then new="normal"; else new="upside-down"; fi

"$DIR/set-orientation.sh" "$target" "$new"

osascript -e "display notification \"product ${target} → ${new}\" with title \"MagicMirror\"" >/dev/null 2>&1 || true
