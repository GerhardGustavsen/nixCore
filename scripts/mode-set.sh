#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/mode/state"
SERVICE="awake.service"

# Colors
SERVER_COLOR="#002199"   # blue in server mode
NORMAL_COLOR="#151515"   # your theme.bg_normal

# --- helpers ---
err() { printf 'ERROR: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

mode_from_file() {
  if [[ -f "$STATE_FILE" ]]; then
    tr -d ' \t\r\n' < "$STATE_FILE"
  else
    echo normal
  fi
}

unit_exists_user() {
  systemctl --user list-unit-files | awk '{print $1}' | grep -qx "$SERVICE"
}

sleep_status() {
  systemctl --user is-active --quiet "$SERVICE" && echo OFF || echo ON
}

sshd_status() {
  systemctl is-active --quiet sshd 2>/dev/null && echo ON || echo OFF
}

safe_start_sshd() { sudo systemctl start sshd 2>/dev/null || err "failed to start sshd"; }
safe_stop_sshd()  { sudo systemctl stop  sshd 2>/dev/null || err "failed to stop sshd";  }

safe_start_inhibitor() {
  if unit_exists_user; then
    systemctl --user start "$SERVICE" 2>/dev/null || err "failed to start $SERVICE"
  else
    err "user unit $SERVICE not found (define it in Home Manager)"
  fi
}
safe_stop_inhibitor() {
  if unit_exists_user; then
    systemctl --user stop "$SERVICE" 2>/dev/null || err "failed to stop $SERVICE"
  fi
}

# Ask Awesome to change the bar bg (best-effort, no hard fail)
set_bar_color() {
  local color="$1"
  command -v awesome-client >/dev/null 2>&1 || { err "awesome-client not found; skipping bar color"; return 0; }
  [[ -z "${DISPLAY:-}" ]] && { err "DISPLAY not set; skipping bar color"; return 0; }
  awesome-client "awesome.emit_signal('mode::bar_bg', '$color')" >/dev/null 2>&1 || err "could not signal AwesomeWM"
}

# --- apply ---
MODE="$(mode_from_file)"
case "$MODE" in
  server)
    have systemctl || { err "systemctl missing"; exit 1; }
    have sudo || err "sudo missing (needed to control sshd)"
    safe_start_sshd
    safe_start_inhibitor
    set_bar_color "$SERVER_COLOR"
    ;;
  normal|*)
    have systemctl || { err "systemctl missing"; exit 1; }
    have sudo || err "sudo missing (needed to control sshd)"
    safe_stop_sshd
    safe_stop_inhibitor
    set_bar_color "$NORMAL_COLOR"
    MODE="normal"
    ;;
esac

# --- concise summary (queried live) ---
echo "${MODE} mode activated!"
echo "sleep: $(sleep_status)"
echo "sshd:  $(sshd_status)"
