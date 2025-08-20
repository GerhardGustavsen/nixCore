#!/usr/bin/env bash

# Log events
exec >> /tmp/startup_debug.log 2>&1
echo "Startup script started at $(date)"

# Select mode
$HOME/nixCore/scripts/mode-set.sh &

# Start battery monitor
rm /tmp/battery_warning_shown
$HOME/nixCore/scripts/battery-monitor.sh &
echo "Started battery waring script"

# Cursor hider
unclutter -idle 1 -jitter 2 -root &
echo "Started unclutter"

# Set up screenlock
LOCK="$HOME/nixCore/scripts/blurlock.sh"
xidlehook --not-when-audio --not-when-fullscreen --timer 400 "$LOCK" '' &
echo "Started idle screen lock"

# Kill and restart udiskie
pkill udiskie
sleep 0.1 && udiskie &
echo "Started udiskie"

# Restart services so they see environment variables:
systemctl --user restart hw-events.service &
echo "Restarting hw-events service (async)"

# Detect and change screen setup
autorandr --change
echo "Tried to display on multiple screens"

# Set the cursor so it's not perpetually loading
xsetroot -cursor_name left_ptr
sleep 0.1
xsetroot -cursor_name left_ptr
sleep 0.1
xsetroot -cursor_name left_ptr
echo "Hid cursor loading"

exit 0
