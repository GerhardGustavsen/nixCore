#!/usr/bin/env bash

set -euo pipefail

DEV="intel_backlight"           # Device (brightnessctl -l # to list all devices)
DIR="$1"                        # user inputt {up | down}
CUR=$(brightnessctl get "$DEV") # get current brightness

# Define brightness levels
levels=(0 1 100 3000 7500)

NEW_VAL=$(brightnessctl max "$DEV")
for ((i = 0; i < ${#levels[@]}; i++)); do
  if ((levels[i] == CUR)); then
    # move one step
    if [[ "$DIR" == "up" ]]; then
      if ((i + 1 < ${#levels[@]})); then
        NEW_VAL=${levels[i + 1]}
      fi
    else
      if ((i - 1 >= 0)); then
        NEW_VAL=${levels[i - 1]}
      else
        NEW_VAL=${CUR}
      fi
    fi
  fi
done

# apply it
brightnessctl set "${NEW_VAL}" "$DEV"
