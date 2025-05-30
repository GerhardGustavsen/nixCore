#!/usr/bin/env bash

# Cursor hider
unclutter -idle 1 -jitter 2 -root &

# Save screen config at bootup
autorandr --save bootup

# Kill and restart udiskie
pkill udiskie
sleep 0.1 && udiskie &

# Restart services so they see enviroment varriables:
systemctl --user restart mc-connect.service

# Set the cursor so its not perpetually loading
xsetroot -cursor_name left_ptr

# Diable middle mouse btn on maousepad:
# spawn.once({"xinput", "set-button-map", "13", "1", "0", "3", "4", "5", "6", "7"})

exit 0
