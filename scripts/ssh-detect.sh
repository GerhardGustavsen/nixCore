#!/usr/bin/env bash
set -euo pipefail

# Color only when active; on exit we ALWAYS run `mode status` to restore your mode color.
ORANGE="${ORANGE:-#ff8c00}"
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
    info="$(loginctl show-session "$sid" -p Remote -p Service -p State 2>/dev/null || true)"
    if grep -q '^Service=sshd$' <<<"$info" && grep -q '^Remote=yes$' <<<"$info" && grep -q '^State=active$' <<<"$info"; then
      cnt=$((cnt+1))
    fi
  done < <(loginctl list-sessions --no-legend 2>/dev/null || true)
  echo "$cnt"
}

apply_transition() {
  # called only when count actually changes
  local prev="$1" now="$2"
  if (( prev == 0 && now > 0 )); then
    set_bar_color "$ORANGE"
    notify "SSH connected" "$now active session(s)"
  elif (( prev > 0 && now == 0 )); then
    # restore via your mode tool (blue stays blue if you're in server mode)
    if command -v mode >/dev/null 2>&1; then
      mode status >/dev/null 2>&1 || true
    fi
    notify "SSH disconnected" "No active SSH sessions"
  fi
}

# Initial state (don’t touch color unless there’s already an active SSH)
last="$(active_ssh_count)"
if (( last > 0 )); then set_bar_color "$ORANGE"; fi

# Build journal follower – cover main + per-connection units and both tags
# Note: quoting for the template unit requires eval.
JOURNAL_CMD="journalctl -af -o cat --since now -u sshd.service -u 'sshd@*' -t sshd -t sshd-session"

# Case-insensitive match for many distro phrasings of open/close
shopt -s nocasematch

# One loop; recompute count only on relevant lines
while IFS= read -r line; do
  # Normalize whitespace
  l="${line//[$'\r\n']/}"
  if [[ "$l" == *accepted* || "$l" == *"session opened for user "* || "$l" == *"starting session "* || "$l" == *"opened session "* ]]; then
    now="$(active_ssh_count)"; if [[ "$now" != "$last" ]]; then apply_transition "$last" "$now"; last="$now"; fi
  elif [[ "$l" == *"session closed for user "* || "$l" == *"disconnected from "* || "$l" == *"received disconnect"* || "$l" == *"closed session "* || "$l" == *"removed session "* || "$l" == *"connection closed by "* ]]; then
    now="$(active_ssh_count)"; if [[ "$now" != "$last" ]]; then apply_transition "$last" "$now"; last="$now"; fi
  fi
done < <(eval "$JOURNAL_CMD")
