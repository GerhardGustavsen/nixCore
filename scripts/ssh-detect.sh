#!/usr/bin/env bash
# ssh-bar-utmp-logind.sh — set bar orange while any SSH session is active; else blue.
# Requirements: inotifywait (inotify-tools), loginctl, awesome-client (for signaling), optional dunstify.

set -euo pipefail

ORANGE="${ORANGE:-#ff8c00}"
BLUE="${BLUE:-#002199}"        # your requested "no-SSH" color
UTMP="/run/utmp"

err(){ printf '[sshbar] %s\n' "$*" >&2; }

set_bar_color() {
  local color="$1"
  command -v awesome-client >/dev/null 2>&1 || { err "awesome-client not found"; return 0; }
  [[ -z "${DISPLAY:-}" ]] && { err "DISPLAY not set"; return 0; }
  awesome-client "awesome.emit_signal('mode::bar_bg', '$color')" >/dev/null 2>&1 || err "awesome-client failed"
}

notify() {
  command -v dunstify >/dev/null 2>&1 || return 0
  dunstify -a "ssh" "$1" "$2" -u low -t 2000 >/dev/null 2>&1 || true
}

# Count active remote SSH sessions via logind (authoritative)
ssh_count() {
  local cnt=0
  # list session IDs; ignore errors if none
  while read -r sid _; do
    [[ -n "${sid:-}" ]] || continue
    # Read values (one per line, in this order). --value avoids "key=" noise.
    readarray -t vals < <(loginctl show-session "$sid" -p Service -p Remote -p State --value 2>/dev/null || true)
    local service="${vals[0]:-}" remote="${vals[1]:-}" state="${vals[2]:-}"
    if [[ "$service" == "sshd" && "$remote" == "yes" && "$state" == "active" ]]; then
      ((cnt++))
    fi
  done < <(loginctl list-sessions --no-legend 2>/dev/null || true)
  echo "$cnt"
}

# Debounced read to survive logind’s short lag after utmp changes
stable_count() {
  local a b
  a="$(ssh_count)"
  sleep 0.25
  b="$(ssh_count)"
  # If still changing, trust the second read
  echo "$b"
}

# --- init ---
command -v inotifywait >/dev/null 2>&1 || { err "inotifywait (inotify-tools) is required"; exit 1; }

# Set initial color based on current state
last="$(ssh_count)"
if (( last > 0 )); then
  set_bar_color "$ORANGE"
else
  set_bar_color "$BLUE"
fi

# --- event loop: react to utmp modifications (both login and logout) ---
# Suppress inotifywait’s own output; loop forever.
while inotifywait -q -e modify "$UTMP" >/dev/null 2>&1; do
  now="$(stable_count)"
  # Only act when the number of sessions actually changes
  if (( now != last )); then
    if (( now > 0 )); then
      set_bar_color "$ORANGE"
      notify "SSH connected" "$now active session(s)"
    else
      set_bar_color "$BLUE"
      notify "SSH disconnected" "No active SSH sessions"
    fi
    last="$now"
  fi
done
