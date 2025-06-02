#!/usr/bin/env bash

echo "[+] Watching systemd for microcontroller plug events..."

LOCK_FILE="/tmp/mc-watcher-last-trigger"
COOLDOWN_SEC=3

dbus-monitor --system "type='signal',interface='org.freedesktop.systemd1.Manager',member='UnitNew'" |
    while read -r line; do
        if echo "$line" | grep -qE 'ttyACM|MicroPython|serial-by-id'; then

            now=$(date +%s)
            last=$(cat "$LOCK_FILE" 2>/dev/null || echo 0)
            delta=$((now - last))

            if ((delta < COOLDOWN_SEC)); then
                continue
            fi

            echo "[trigger] Device event detected"

            # Dynamically select the newest /dev/ttyACM* device
            PORT=$(ls -t /dev/ttyACM* 2>/dev/null | head -n1)

            if [[ -z "$PORT" ]]; then
                echo "[error] No /dev/ttyACM* found"
                continue
            fi

            # Check if the REPL terminal is already running
            REPL_WIN_ID=$(xdotool search --name "^Pico Console$" 2>/dev/null | head -n1)

            if [[ -n "$REPL_WIN_ID" ]]; then
                echo "[info] Terminal already running, skipping spawn"
            else
                echo "[connect] Launching mpremote for $PORT"
                echo "$now" >"$LOCK_FILE"

                xfce4-terminal \
                    --title="Pico Console" \
                    -e "bash -c 'while true; do mpremote connect $PORT repl; sleep 3; done'" &
            fi

            notify-send "MicroPython device detected!" "To run a program:\n\nmcflash path/to/program.py"
        fi
    done
