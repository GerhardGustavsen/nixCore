#!/usr/bin/env bash
set -euo pipefail

ORANGE="${ORANGE:-#ff8c00}"
DEFAULT_COLOR="${DEFAULT_COLOR:-#151515}"   # fallback if `mode status` isn't present
LOG_UNIT="${LOG_UNIT:-sshd}"
PAGER=

err(){ printf '[sshbar] %s\n' "$*" >&2; }

set_bar_color() {
  local color="$1"
  command -v awesome-client >/dev/null 2>&1 || { err "awesome-client not found"; return 0; }
  [[ -z "${DISPLAY:-}" ]] && { err "DISPLAY not set"; return 0; }
  awesome-client "awesome.emit_signal('mode::bar_bg', '$color')" >/dev/null 2>&1 || err "awesome-client failed"
}

notify() {
  command -v dunstify >/dev/null 2>&1 || return 0
  dunstify -a "ssh" "$1" "$2" -u low -t 2500 >/dev/null 2>&1 || true
}

active_ssh_count() {
  local cnt=0
  while read -r sid _; do
    [[ -n "$sid" ]] || continue
    local info
    info="$(loginctl show-session "$sid" -p Remote -p RemoteHost -p Service -p State 2>/dev/null || true)"
    if grep -q '^Service=sshd$' <<<"$info" && grep -q '^Remote=yes$' <<<"$info" && grep -q '^State=active$' <<<"$info"; then
      cnt=$((cnt+1))
    fi
  done < <(loginctl list-sessions --no-legend 2>/dev/null || true)
  echo "$cnt"
}

apply_state() {
  local now="$1"
  if (( now > 0 )); then
    set_bar_color "$ORANGE"
    notify "SSH connected" "$now active session(s)"
  else
    if command -v mode >/dev/null 2>&1; then
      mode status >/dev/null 2>&1 || set_bar_color "$DEFAULT_COLOR"
    else
      set_bar_color "$DEFAULT_COLOR"
    fi
    notify "SSH disconnected" "No active SSH sessions"
  fi
}

last="$(active_ssh_count)"; apply_state "$last"

# Event-driven loop: journalctl follows in real time.
journalctl -fu "$LOG_UNIT" -o cat | \
while IFS= read -r line; do
  # Only react on lines that imply session count changes.
  case "$line" in
    *"Accepted "*|*"session opened for user "*|*"session closed for user "*|*"Disconnected from user "*|*"Disconnected from "*)
      now="$(active_ssh_count)"
      if [[ "$now" != "$last" ]]; then
        apply_state "$now"
        last="$now"
      fi
      ;;
    *) : ;;
  esac
done