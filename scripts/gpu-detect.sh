#!/usr/bin/env bash
set -eu
mkdir -p /run/xorg

# check if any NVIDIA device exists
if grep -Rqs 0x10de /sys/bus/pci/devices; then
  # pick the first NVIDIA VGA/3D controller from lspci
  addr="$(lspci -Dnn | grep -E 'VGA|3D' | grep -m1 10de: | cut -d' ' -f1)"
  if [ -n "${addr:-}" ]; then
    rest="${addr#*:}"                 # e.g. 0c:00.0
    bus="${rest%%:*}"; rest="${rest#*:}"
    slot="${rest%%.*}"; func="${rest#*.}"
    bus_dec=$((16#$bus))
    slot_dec=$((16#$slot))

    cat > /run/xorg/10-gpu.conf <<EOF
Section "Device"
  Identifier "NVIDIA"
  Driver     "nvidia"
  BusID      "PCI:${bus_dec}:${slot_dec}:${func}"
  Option     "AllowExternalGpus" "true"
EndSection

Section "Screen"
  Identifier "Screen0"
  Device     "NVIDIA"
EndSection
EOF
    exit 0
  fi
fi

# fallback to Intel
echo "# Intel via modesetting" > /run/xorg/10-gpu.conf
