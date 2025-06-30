#!/usr/bin/env bash

# One positional argument: blur radius (default to 2)
RADIUS=0x${1:-2}

# Output image path
IMG=/tmp/screenshot.png

# Capture screen with maim and blur it
dunstify -u normal -t 700 -h string:fgcolor:#00ffff "🔒 Locking Computer..."
maim -u | magick - -scale 20% -blur "$RADIUS" -resize 500% "$IMG"

# Lock screen with blurred image
i3lock -i "$IMG"