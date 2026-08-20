#!/bin/zsh
# apply-normal.sh [product-id]
# Force a specific trackpad model normal (default: toggle-target).
set -euo pipefail

DIR="$HOME/.hammerspoon/trackpad-orientation"
target="${1:-$(awk '/^toggle-target[[:space:]]/{print $2; exit}' "$DIR/orient.conf" 2>/dev/null || true)}"
if [[ -z "$target" ]]; then
  echo "${0:t}: pass a product id or add 'toggle-target <id>' to orient.conf" >&2
  exit 64
fi
"$DIR/set-orientation.sh" "$target" normal
