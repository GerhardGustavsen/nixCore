#!/usr/bin/env bash

# One positional argument: blur radius (default to 2)
RADIUS=0x${1:-2}

# Use magick for everything (avoid convert entirely)
xwd -root -silent | magick xwd:- -scale 20% -blur "$RADIUS" -resize 500% /tmp/screenshot.png

# Lock screen
i3lock -i /tmp/screenshot.png
exit 0