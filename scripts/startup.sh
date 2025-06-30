#!/usr/bin/env bash

# Cursor hider
unclutter -idle 1 -jitter 2 -root &

# Save screen config at bootup
autorandr --save bootup

# Kill and restart udiskie
pkill udiskie
sleep 0.1 && udiskie &

# Restart services so they see enviroment varriables:
systemctl --user restart new-device.service

autorandr --change

# Set the cursor so its not perpetually loading
xsetroot -cursor_name left_ptr
sleep 0.1
xsetroot -cursor_name left_ptr
sleep 0.1
xsetroot -cursor_name left_ptr

exit 0
