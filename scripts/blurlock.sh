#!/usr/bin/env bash
# lock.sh [hex_blur]   e.g. lock.sh 2  -> RADIUS=0x2

set -euo pipefail

RADIUS=0x${1:-1}
IMG=/tmp/screenshot.png
OVER=/tmp/lock_overlay.png

# Pick a Nerd Font file (adjust the grep if your font differs)
FONTFILE="$(fc-list -f '%{file}\n' | grep -i -E 'SymbolsNerdFontMono|NerdFont.*Mono' | head -n1 || true)"
if [[ -z "${FONTFILE}" ]]; then
  dunstify -u critical "No Nerd Font found. Install a Nerd Font (e.g. Symbols Nerd Font Mono)."
  exit 1
fi

# U+F023 = Font Awesome lock (PUA) – safer than pasting the glyph
LOCK_CHAR=$'\ue672'

POINTSIZE=160
FILL="#BABABA"
STROKE="#292929"
STROKEWIDTH=2

dunstify -u normal -t 700 -h string:fgcolor:#00ffff "🔒 Locking Computer..."

# Grab & blur
maim -u | magick - -scale 10% -blur "$RADIUS" -resize 1000% "$IMG"

# Build a transparent overlay with the lock, then composite it
magick -size 600x600 xc:none \
  -gravity center \
  -fill "$FILL" -stroke "$STROKE" -strokewidth "$STROKEWIDTH" \
  -font "$FONTFILE" -pointsize "$POINTSIZE" \
  -annotate -1-6 "$LOCK_CHAR" \
  "$OVER"

# If annotate failed (e.g., missing glyph), $OVER may be empty/transparent; detect that
if ! magick identify -format '%[channels]' "$OVER" >/dev/null 2>&1; then
  dunstify -u critical "Failed to render glyph from $FONTFILE"
  exit 1
fi

# Composite overlay at center
magick "$IMG" "$OVER" -gravity center -compose over -composite "$IMG"

# Lock
exec i3lock -i "$IMG"
