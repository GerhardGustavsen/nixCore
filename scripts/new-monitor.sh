#!/usr/bin/env bash

STATE_FILE="/tmp/connected-screens"

inotifywait -mq -e create /tmp | while read -r path action file; do

  # Only act on hw-trigger-* files
  if [[ "$file" =~ ^hw-trigger-[0-9]+-(.+)$ ]]; then
    type="${BASH_REMATCH[1]}"
    trigger_path="/tmp/$file"
  else
    continue
  fi

  # Only react to monitor events
  if [ "$type" != "monitor" ]; then
    continue
  fi

  sleep 0.5  # Let X settle before querying xrandr

  CURRENT=$(xrandr --query | grep ' connected' | awk '{print $1}' | sort)

  if [ ! -f "$STATE_FILE" ]; then
    echo "$CURRENT" > "$STATE_FILE"
    continue
  fi

  PREVIOUS=$(sort "$STATE_FILE")
  echo "$CURRENT" > "$STATE_FILE"

  NEW=$(comm -13 <(echo "$PREVIOUS") <(echo "$CURRENT"))
  REMOVED=$(comm -23 <(echo "$PREVIOUS") <(echo "$CURRENT"))

  if [ -n "$REMOVED" ]; then
      notify-send "🖥️ Monitor disconnected" "$REMOVED"
    autorandr --change
  fi

  if [ -n "$NEW" ]; then
    autorandr --change

    id=$(dunstify --action="arandr,Open layout editor" \
                  --urgency=normal \
                  --timeout=15000 \
                  --printid \
                  "🖥️ New screen detected" "$NEW Click to configure")

    if [ -n "$id" ]; then
        action=$(echo "$id" | sed -n 2p)
        if [ "$action" = "arandr" ]; then
            arandr &
            notify-send  "💡 Enable autoconection:" "autorandr --save setup_name"
        fi

    fi
  fi
done