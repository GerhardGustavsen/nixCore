#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/mode/state"
APPLIER="$HOME/nixCore/scripts/mode-set.sh"

usage(){ echo "Usage: mode {server|normal|status}"; exit 1; }

mkdir -p "$(dirname "$STATE_FILE")"

case "${1:-}" in
  server|normal)
    printf '%s\n' "$1" > "$STATE_FILE"
    [[ -x "$APPLIER" ]] || { echo "Error: $APPLIER not found/executable"; exit 1; }
    exec "$APPLIER"
    ;;

  status)
    [[ -x "$APPLIER" ]] || { echo "Error: $APPLIER not found/executable"; exit 1; }
    exec "$APPLIER"
    ;;

  *)
    usage
    ;;
esac
