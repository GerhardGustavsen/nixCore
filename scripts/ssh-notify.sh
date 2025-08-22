#!/usr/bin/env bash
# ssh-bar-notify.sh open|close
set -euo pipefail

# --- config ---
ORANGE="${ORANGE:-#ff8c00}"
DEFAULT_COLOR="${DEFAULT_COLOR:-#151515}"   # used only if `mode status` not found
STATE="/run/ssh_active_count"

# Desktop user: default to PAM user; override via env DESKTOP_USER if needed
DESKTOP_USER="${DESKTOP_USER:-${PAM_USER:-gg}}"

# --- helpers ---
err(){ printf '[sshbar] %s\n' "$*" >&2; }

# Uses your Awesome signal
set_bar_color() {
  local color="$1"
  command -v awesome-client >/dev/null 2>&1 || { err "awesome-client not found; skip"; return 0; }
  [[ -z "${DISPLAY:-}" ]] && { err "DISPLAY not set; skip"; return 0; }
  awesome-client "awesome.emit_signal('mode::bar_bg', '$color')" >/dev/null 2>&1 || err "awesome-client failed"
}

notify() {
  command -v dunstify >/dev/null 2>&1 || return 0
  dunstify -a "ssh" "$1" "$2" -u low -t 3000 || true
}

# Prepare env so awesome-client works from PAM
uid="$(id -u "$DESKTOP_USER")"
export XDG_RUNTIME_DIR="/run/user/$uid"
export DISPLAY="${DISPLAY:-:0}"

# Try to find awesome-client in common Nix paths if PATH is bare
if ! command -v awesome-client >/dev/null 2>&1; then
  for p in "/home/$DESKTOP_USER/.nix-profile/bin" "/etc/profiles/per-user/$DESKTOP_USER/bin" "/run/current-system/sw/bin"; do
    [[ -x "$p/awesome-client" ]] && export PATH="$p:$PATH"
  done
fi

# --- logic with tiny refcount ---
read_count(){ [[ -f "$STATE" ]] && cat "$STATE" || echo 0; }
write_count(){ echo "$1" > "$STATE"; }

case "${1:-}" in
  open)
    c="$(read_count)"; c=$((c+1)); write_count "$c"
    if (( c == 1 )); then set_bar_color "$ORANGE"; fi
    notify "SSH connected" "${PAM_USER:-?}@${PAM_RHOST:-local}"
    ;;
  close)
    c="$(read_count)"; (( c > 0 )) && c=$((c-1)); write_count "$c"
    notify "SSH disconnected" "${PAM_USER:-?}@${PAM_RHOST:-local}"
    if (( c == 0 )); then
      if command -v mode >/dev/null 2>&1; then
        mode status >/dev/null 2>&1 || set_bar_color "$DEFAULT_COLOR"
      else
        set_bar_color "$DEFAULT_COLOR"
      fi
    fi
    ;;
  *)
    err "usage: $0 open|close"; exit 2;;
esac
