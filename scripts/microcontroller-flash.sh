#!/usr/bin/env bash

FILE="$1"
PORT="${2:-$(ls -t /dev/ttyACM* 2>/dev/null | head -n1)}"
REPL_TITLE="Pico Console"

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
    echo "[error] Must provide valid .py file"
    exit 1
fi

if [[ -z "$PORT" || ! -e "$PORT" ]]; then
    echo "[error] Invalid or missing port"
    exit 1
fi

echo "[info] Flashing '$FILE' to $PORT"

# Kill the process using the serial port (e.g., REPL)
PID=$(lsof "$PORT" 2>/dev/null | awk 'NR>1 {print $2}' | head -n1)
if [[ -n "$PID" ]]; then
    kill "$PID"
    sleep 0.3
fi

# Flash the file
if ! mpremote connect "$PORT" fs cp "$FILE" :main.py; then
    echo "[error] Flashing failed"
    exit 1
fi

REPL_WIN_ID=$(xdotool search --name "^Pico Console$" 2>/dev/null | head -n1)

if [[ -n "$REPL_WIN_ID" ]]; then
    xdotool windowactivate "$REPL_WIN_ID"
    xdotool key Return
    xdotool key Return
    xdotool key Return
    xdotool type --delay 20 "exec(open('main.py').read())"
    xdotool key Return
else
    echo "[info] No REPL terminal open, skipping restart"
fi

echo "[✓] Flash complete"
