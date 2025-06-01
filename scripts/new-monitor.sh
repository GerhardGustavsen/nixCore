#!/usr/bin/env bash

STATE_FILE="/tmp/connected-screens"

# Wait until a monitor event occurs
inotifywait -e create /tmp | while read path action file; do
  [ "$file" != "hw-event.trigger" ] && continue

  # Clean up
  rm -f /tmp/hw-event.trigger

  echo "tet"

  # Get last hw-event and extract type
  line=$(tail -n 1 /tmp/hw-events.log)
  timestamp=$(echo "$line" | awk '{print $1}')
  type=$(echo "$line" | awk '{print $2}')

  [ "$type" != "monitor" ] && continue

  # Get current monitor setup (sorted list of connected outputs)
  CURRENT=$(xrandr --query | grep ' connected' | awk '{print $1}' | sort)

  # First run: store and exit
  if [ ! -f "$STATE_FILE" ]; then
      echo "$CURRENT" >"$STATE_FILE"
      exit 0
  fi

  PREVIOUS=$(cat "$STATE_FILE")
  echo "$CURRENT" >"$STATE_FILE"

  # Compare
  NEW=$(comm -13 <(echo "$PREVIOUS") <(echo "$CURRENT"))
  REMOVED=$(comm -23 <(echo "$PREVIOUS") <(echo "$CURRENT"))

  if [ -n "$REMOVED" ]; then
      notify-send "🖥️ Monitor(s) disconnected:" "$REMOVED"
      autorandr --change
  fi

  if [ -n "$NEW" ]; then
      notify-send "🖥️ New screen detected:\n$NEW" "\nTo save setup: \nautorandr --save setup_name"
      autorandr --change
      arandr &
  fi

  # One event processed, then exit
  exit 0
done
