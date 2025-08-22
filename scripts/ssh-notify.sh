#!/usr/bin/env bash
# ssh-bar-notify.sh open|close
set -euo pipefail

# --- config you may tweak ---
DESKTOP_USER="gg"                                 # user running AwesomeWM
ACTIVE_BAR_COLOR="${ACTIVE_BAR_COLOR:-#ff8c00}"   # bright orange
DEFAULT_BAR_COLOR="${DEFAULT_BAR_COLOR:-#222222}" # your normal bar color
STATE_FILE="/run/ssh_active_count"
LOCK_FILE="/run/ssh_notify.lock"

# --- helpers ---
err(){ printf '[ssh-notify] %s\n' "$*" >&2; }

# Your function (unaltered), but we'll ensure DISPLAY and awesome-client.
set_bar_color() {
  local color="$1"
  command -v awesome-client >/dev/null 2>&1 || { err "awesome-client not found; skipping bar color"; return 0; }
  [[ -z "${DISPLAY:-}" ]] && { err "DISPLAY not set; skipping bar color"; return 0; }
  awesome-client "awesome.emit_signal('mode::bar_bg', '$color')" >/dev/null 2>&1 || err "could not signal AwesomeWM"
}

# --- locate Awesome socket + prep env so awesome-client works from PAM ---
uid=$(id -u "$DESKTOP_USER")
export XDG_RUNTIME_DIR="/run/user/$uid"
# awesome-client talks over ${XDG_RUNTIME_DIR}/awesome; it doesn't *need* DISPLAY,
# but your function checks DISPLAY, so set a sane default.
export DISPLAY="${DISPLAY:-:0}"

# Try to ensure awesome-client is reachable even from PAM PATH
if ! command -v awesome-client >/dev/null 2>&1; then
  for p in \
    "/home/$DESKTOP_USER/.nix-profile/bin/awesome-client" \
    "/etc/profiles/per-user/$DESKTOP_USER/bin/awesome-client" \
    "/run/current-system/sw/bin/awesome-client"
  do
    [[ -x "$p" ]] && export PATH="$(dirname "$p"):$PATH"
  done
fi

# --- refcount with lock to handle multiple SSH sessions ---
mkdir -p /run
exec 9>"$LOCK_FILE"
flock 9

count=0
[[ -f "$STATE_FILE" ]] && read -r count < "$STATE_FILE" || true

case "${1:-}" in
  open)
    : $((count++))
    echo "$count" > "$STATE_FILE"
    if [[ "$count" -eq 1 ]]; then
      set_bar_color "$ACTIVE_BAR_COLOR"
    fi
    ;;
  close)
    if (( count > 0 )); then : $((count--)); fi
    echo "$count" > "$STATE_FILE"
    if [[ "$count" -eq 0 ]]; then
      set_bar_color "$DEFAULT_BAR_COLOR"
    fi
    ;;
  *)
    err "usage: $0 open|close"
    exit 2
    ;;
esac
