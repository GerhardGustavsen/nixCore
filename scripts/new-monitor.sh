#!/usr/bin/env bash

STATE_FILE="/tmp/connected-screens"

# Get system uptime in seconds
UPTIME=$(cut -d. -f1 /proc/uptime)

# Get connected outputs, excluding internal display
CURRENT=$(xrandr --query | grep ' connected' | awk '{print $1}' | sort)

# If no previous state, store current and exit
if [ ! -f "$STATE_FILE" ]; then
    echo "$CURRENT" >"$STATE_FILE"
    exit 0
fi

PREVIOUS=$(cat "$STATE_FILE")
echo "$CURRENT" >"$STATE_FILE"

# Compare to detect new and removed screens
NEW=$(comm -13 <(echo "$PREVIOUS") <(echo "$CURRENT"))
REMOVED=$(comm -23 <(echo "$PREVIOUS") <(echo "$CURRENT"))

# Only notify and react if system has been up > 10s
if [ "$UPTIME" -gt 10 ]; then
    if [ -n "$REMOVED" ]; then
        notify-send "🖥️ Monitor(s) disconnected:" "$REMOVED"
        autorandr --change
    fi

    if [ -n "$NEW" ]; then
        notify-send "🖥️ New screen detected:\n$NEW" "\n to save screen setup: \nautorandr --save setup_name"
        autorandr --change
        arandr
    fi
fi
