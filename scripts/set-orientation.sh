#!/bin/zsh
# set-orientation.sh <product-id> <normal|upside-down>
#
# Saves the desired orientation for one ProductID, then applies it immediately.
# A disconnected target may be configured for the watcher to apply later; an
# actual MultitouchSupport rejection is reported and returned to the caller.
set -euo pipefail

DIR="$HOME/.hammerspoon/trackpad-orientation"
CONF="$DIR/orient.conf"

product="${1:-}"; orient="${2:-}"
case "$product" in
  ''|*[!0-9]*) product="" ;;
esac
case "$orient" in
  normal|upside-down) ;;
  *) orient="" ;;
esac
if [[ -z "$product" || -z "$orient" ]]; then
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

if "$DIR/mt-orient" apply; then
  exit 0
else
  rc=$?
  if (( rc == 2 )); then
    echo "orientation saved; no configured trackpad is currently connected" >&2
    exit 0
  fi
  exit "$rc"
fi
