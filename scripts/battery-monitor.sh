#!/usr/bin/env bash

THRESHOLD=15
BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"
POPUP_EXEC="$HOME/nixCore/batNotify/battery_popup.run"
INTERVAL=60  # seconds between checks — edit this to control frequency
STATE_FILE="/tmp/battery_warning_shown"

while true; do
    BATTERY=$(cat /sys/class/power_supply/BAT0/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT0/status)

    if [[ "$BATTERY" -le "$THRESHOLD" && "$STATUS" != "Charging" ]]; then
        if [[ ! -f "$STATE_FILE" ]]; then
            "$POPUP_EXEC" &
            touch "$STATE_FILE"
        fi
    else
        [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
    fi

    sleep "$INTERVAL"
done
