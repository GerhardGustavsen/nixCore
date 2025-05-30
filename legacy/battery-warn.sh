#!/usr/bin/env bash

THRESHOLD=5
NOTIFIED=0
YAD_PID=""

while :; do
  CAPACITY=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo 100)
  STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo "Unknown")

  # NOW=$(cat /sys/class/power_supply/BAT*/energy_now 2>/dev/null || echo 1)
  # FULL=$(cat /sys/class/power_supply/BAT*/energy_full 2>/dev/null || echo 1)

  # compute % with two decimals
  # PERCENT=$(awk "BEGIN{printf \"%.2f\", $NOW*100/$FULL}")

  if [[ "$STATUS" = "Discharging" && "$CAPACITY" -le "$THRESHOLD" ]]; then
    if [[ $NOTIFIED -eq 0 ]]; then
      yad \
        --css="$HOME/.config/gtk-3.0/yad.css" \
        --skip-taskbar \
        --undecorated \
        --sticky \
        --title="Battery-Low-Alert" \
        --geometry=center \
        --no-buttons \
        --borders=1 \
        --text="<span>❮ Battery low > ${THRESHOLD}% remaining ❯</span>" \
        &
      YAD_PID=$!
      NOTIFIED=1
    fi
  else
    if [[ $NOTIFIED -eq 1 ]]; then
      # Kill the YAD dialog when battery is OK/charging again
      kill "$YAD_PID" 2>/dev/null || true

      NOTIFIED=0
      YAD_PID=""
    fi
  fi

  sleep 60
done
