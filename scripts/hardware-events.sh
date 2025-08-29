#!/usr/bin/env bash

handle_monitor() {
  sleep 0.5  # Let X settle a little

  if [ -d /sys/bus/thunderbolt/devices ] && ls /sys/bus/thunderbolt/devices 1>/dev/null 2>&1 | grep -q .; then
    sleep 10  # Let X settle a lot
  fi

  autorandr --change

  id=$(dunstify --action="arandr,Open layout editor" \
                --urgency=normal \
                --timeout=15000 \
                --printid \
                "🖥️ Monitor change detected" "Click to configure")
  if [ -n "$id" ]; then
      action=$(echo "$id" | sed -n 2p)
      if [ "$action" = "arandr" ]; then
          notify-send  "💡 Enable autoconection:" "autorandr --save setup_name"
          arandr &
      fi
  fi
}

handle_usb() {
  sleep 0.5  # Let USB settle

  PORT=$(ls -t /dev/ttyACM* 2>/dev/null | head -n1)

  if [[ -z "$PORT" ]]; then
      echo "[error] No /dev/ttyACM* found"
      return
  fi

  # Check if it's a MicroPython device
  if ! mpremote devs | grep -q "$PORT"; then
    echo "[skip] $PORT not listed as a MicroPython device"
    return
  fi
  if ! mpremote connect "$PORT" exec "print('MPY')" | grep -q "MPY"; then
      echo "[skip] $PORT does not appear to be running MicroPython"
      return
  fi

  # Check if the REPL terminal is already running
  REPL_WIN_ID=$(xdotool search --name "^Pico Console$" 2>/dev/null | head -n1)
  if [[ -n "$REPL_WIN_ID" ]]; then
      echo "[info] Terminal already running, skipping spawn"
  else
      echo "[connect] Launching mpremote for $PORT"
      xfce4-terminal \
          --title="Pico Console" \
          -e "bash -c 'while true; do mpremote connect $PORT repl; sleep 3; done'" &
  fi

  notify-send "MicroPython device detected!" "To run a program:\n\nmcflash path/to/program.py"
}


inotifywait -mq -e create /tmp | while read -r path action file; do

  # Only act on hw-trigger-* files
  if [[ "$file" =~ ^hw-trigger-[0-9]+-(.+)$ ]]; then
    type="${BASH_REMATCH[1]}"
    trigger_path="/tmp/$file"
  else
    continue
  fi

  if [ "$type" == "monitor" ]; then
    handle_monitor
  fi

  if [ "$type" == "usb" ]; then
    handle_usb
  fi

  if [ "$type" == "sleep" ]; then
    $HOME/nixCore/scripts/blurlock.sh
  fi

done