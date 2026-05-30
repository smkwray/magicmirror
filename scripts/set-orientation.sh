#!/bin/zsh
# set-orientation.sh <product-id> <normal|upside-down>
#
# Sets the desired orientation for a specific trackpad model (by ProductID) in
# orient.conf, then applies immediately. The watch daemon live-reloads the config
# (~2s) and self-heals (60s), so the change is durable -- editing the config is
# how we cooperate with the daemon instead of fighting it.
set -euo pipefail

DIR="$HOME/.hammerspoon/trackpad-orientation"
CONF="$DIR/orient.conf"

product="${1:-}"; orient="${2:-}"
if [[ -z "$product" || ( "$orient" != "normal" && "$orient" != "upside-down" ) ]]; then
  echo "usage: set-orientation.sh <product-id> <normal|upside-down>" >&2
  exit 64
fi

touch "$CONF"
if grep -qE "^product[[:space:]]+${product}([[:space:]]|\$)" "$CONF"; then
  tmp="$(mktemp)"
  sed -E "s/^(product[[:space:]]+${product}[[:space:]]+).*/\1${orient}/" "$CONF" > "$tmp"
  mv "$tmp" "$CONF"
else
  printf 'product %s %s\n' "$product" "$orient" >> "$CONF"
fi

# Apply now so the change is instant; the daemon will keep enforcing it.
"$DIR/mt-orient" apply >/dev/null 2>&1 || true
