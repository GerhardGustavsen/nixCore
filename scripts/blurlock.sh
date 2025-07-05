#!/usr/bin/env bash

# One positional argument: blur radius (default to 2)
RADIUS=0x${1:-1}

# Output image path
IMG=/tmp/screenshot.png

# Capture screen with maim and blur it
dunstify -u normal -t 700 -h string:fgcolor:#00ffff "🔒 Locking Computer..."
maim -u | magick - -scale 10% -blur "$RADIUS" -resize 1000% "$IMG"

# Lock screen with blurred image
i3lock -i "$IMG"