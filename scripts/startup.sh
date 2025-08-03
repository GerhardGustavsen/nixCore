#!/usr/bin/env bash

# Cursor hider
unclutter -idle 1 -jitter 2 -root &

# Set upp screenlock
LOCK="$HOME/nixCore/scripts/blurlock.sh"
xidlehook --not-when-audio --not-when-fullscreen --timer 400 "$LOCK" '' &

# Kill and restart udiskie
pkill udiskie
sleep 0.1 && udiskie &

# Restart services so they see enviroment varriables:
systemctl --user restart new-device.service

# Detect anc change screen setupp
autorandr --change

# Set the cursor so its not perpetually loading
xsetroot -cursor_name left_ptr
sleep 0.1
xsetroot -cursor_name left_ptr
sleep 0.1
xsetroot -cursor_name left_ptr

exit 0
