#!/usr/bin/env bash

# Cursor hider
unclutter -idle 1 -jitter 2 -root &

# Start battery monitor (edit CHECK_INTERVAL in script as needed)
"$HOME/nixCore/batNotify/battery_monitor.sh" &

# Set up screenlock
xhost +SI:localuser:gg # i donno if needed
LOCK="$HOME/nixCore/scripts/blurlock.sh"
xidlehook --not-when-audio --not-when-fullscreen --timer 400 "$LOCK" '' &

# Kill and restart udiskie
pkill udiskie
sleep 0.1 && udiskie &

# Restart services so they see environment variables:
systemctl --user restart hw-events.service

# Detect and change screen setup
autorandr --change

# Set the cursor so it's not perpetually loading
xsetroot -cursor_name left_ptr
sleep 0.1
xsetroot -cursor_name left_ptr
sleep 0.1
xsetroot -cursor_name left_ptr

exit 0
