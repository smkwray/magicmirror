#!/bin/zsh
set -euo pipefail

INSTALL_DIR="$HOME/.hammerspoon/trackpad-orientation"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.smkwray.magicmirror.plist"

# Stop the watch daemon first so it does not re-apply while we reset.
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true

# Attempt reset before removing the helper, but do not hide a private-API failure.
reset_failed=0
if [[ -x "$INSTALL_DIR/mt-orient" ]]; then
  "$INSTALL_DIR/mt-orient" reset || rc=$?
  if (( ${rc:-0} != 0 && ${rc:-0} != 2 )); then reset_failed=1; fi
elif [[ -x "$INSTALL_DIR/mt-orientation" ]]; then
  # A pre-mt-orient installation carries the historical helper, whose process
  # status is not trustworthy: it returned 0 even when a setter result was
  # nonzero. Capture its output and inspect every result token.
  legacy_rc=0
  legacy_output="$("$INSTALL_DIR/mt-orientation" normal 2>&1)" || legacy_rc=$?

  legacy_result_seen=0
  legacy_rejected=0
  if print -r -- "$legacy_output" | grep -Eq 'result=-?[0-9]+'; then
    legacy_result_seen=1
  fi
  if print -r -- "$legacy_output" | grep -Eq 'result=-?[1-9][0-9]*([[:space:]]|$)'; then
    legacy_rejected=1
  fi

  legacy_failed=0
  if (( (legacy_rc != 0 && legacy_rc != 2) || legacy_rejected ||
        (legacy_rc == 0 && ! legacy_result_seen) )); then
    legacy_failed=1
    reset_failed=1
  fi

  if [[ -n "$legacy_output" ]]; then
    if (( legacy_failed || legacy_rc == 2 )); then
      print -u2 -r -- "$legacy_output"
    else
      print -r -- "$legacy_output"
    fi
  fi
fi

rm -f "$LAUNCH_AGENT"
rm -rf "$INSTALL_DIR"

if (( reset_failed )); then
  echo "MagicMirror removed, but macOS rejected the orientation reset; reconnect or reset the trackpad manually." >&2
  exit 1
fi
echo "MagicMirror removed and connected external trackpads reset to normal."
