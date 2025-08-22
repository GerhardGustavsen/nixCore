#!/usr/bin/env bash
# Wrapper run by pam_exec. Must NEVER fail.
# We do NOT use `set -e` on purpose.

set -uo pipefail

# --- config you can tweak ---
ORANGE="${ORANGE:-#ff8c00}"
DEFAULT_COLOR="${DEFAULT_COLOR:-#151515}"    # used when restoring via `mode status` isn't available
STATE="/run/ssh_active_count"

# Desktop user (for XDG_RUNTIME_DIR/DISPLAY). Use PAM_USER by default.
DESKTOP_USER="${DESKTOP_USER:-${PAM_USER:-gg}}"

log(){ printf '[sshbar] %s\n' "$*" >&2; }

set_bar_color() {
  local color="$1"
  command -v awesome-client >/dev/null 2>&1 || { log "awesome-client missing"; return 0; }
  [[ -z "${DISPLAY:-}" ]] && { log "DISPLAY not set"; return 0; }
  awesome-client "awesome.emit_signal('mode::bar_bg', '$color')" >/dev/null 2>&1 || log "awesome-client failed"
}

notify() {
  command -v dunstify >/dev/null 2>&1 || return 0
  dunstify -a "ssh" "$1" "$2" -u low -t 2500 >/dev/null 2>&1 || true
}

# Prep env so awesome-client works even from PAM
uid="$(id -u "$DESKTOP_USER" 2>/dev/null || echo 1000)"
export XDG_RUNTIME_DIR="/run/user/$uid"
export DISPLAY="${DISPLAY:-:0}"

# Try a few common Nix paths for awesome-client if PATH is bare
if ! command -v awesome-client >/dev/null 2>&1; then
  for p in "/home/$DESKTOP_USER/.nix-profile/bin" "/etc/profiles/per-user/$DESKTOP_USER/bin" "/run/current-system/sw/bin"; do
    [[ -x "$p/awesome-client" ]] && export PATH="$p:$PATH"
  done
fi

# helpers for tiny refcount
read_count(){ [[ -f "$STATE" ]] && cat "$STATE" 2>/dev/null || echo 0; }
write_count(){ echo "$1" > "$STATE" 2>/dev/null || true; }

action="${1:-}"
case "$action" in
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
    log "usage: $0 open|close"
    ;;
esac

# ABSOLUTELY NEVER FAIL PAM:
exit 0