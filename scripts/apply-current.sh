#!/bin/zsh
# apply-current.sh
# Re-apply the orientations defined in orient.conf, once. (The watch daemon does
# this continuously; this is for manual / one-shot use.)
set -euo pipefail
exec "$HOME/.hammerspoon/trackpad-orientation/mt-orient" apply
