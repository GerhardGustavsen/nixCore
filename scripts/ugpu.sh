#!/usr/bin/env bash
# ugpu — gracefully detach NVIDIA eGPU (Thunderbolt)
# Usage: ugpu [--force]
set -euo pipefail

FORCE="${1:-}"

red(){ printf '\033[91m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[93m%s\033[0m\n' "$*"; }
green(){ printf '\033[92m%s\033[0m\n' "$*"; }

need() { command -v "$1" >/dev/null 2>&1 || { red "missing: $1"; exit 127; }; }
need lspci
need sudo

# 1) Find the NVIDIA GPU and its sibling functions (audio/USB/UCSI)
mapfile -t FUNCS < <(lspci -Dn | awk '/10de:/{print $1}' | sort)
if ((${#FUNCS[@]}==0)); then yellow "No NVIDIA PCI functions found."; exit 0; fi

# Prefer the VGA func as anchor (…:xx:xx.0). Derive its bus:slot prefix.
GPU_FUNC="$(printf '%s\n' "${FUNCS[@]}" | awk -F. '$2=="0"{print; exit}')"
if [[ -z "${GPU_FUNC}" ]]; then GPU_FUNC="${FUNCS[0]}"; fi
BUS_PREFIX="${GPU_FUNC%.*}"             # e.g. 0000:0c:00
SYSFS="/sys/bus/pci/devices"

echo "Detected NVIDIA functions under ${BUS_PREFIX}.x:"
printf '  - %s\n' "${FUNCS[@]}"

# 2) Warn if X/Wayland is active unless --force
if [[ -n "${DISPLAY-}" || "${XDG_SESSION_TYPE-}" = "wayland" ]]; then
  if [[ "${FORCE}" != "--force" ]]; then
    yellow "You appear to be in a graphical session. Safer path:"
    echo "  1) Ctrl+Alt+F3 → TTY, login"
    echo "  2) sudo systemctl stop display-manager"
    echo "  3) re-run: ugpu --force"
    exit 1
  fi
fi

# 3) Stop the display manager if running (only with --force)
if [[ "${FORCE}" == "--force" ]] && command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet display-manager; then
    yellow "Stopping display-manager…"
    sudo systemctl stop display-manager || true
  fi
fi

# 4) Make sure no processes hold /dev/nvidia* (kill as last resort)
if command -v fuser >/dev/null 2>&1; then
  if fuser -v /dev/nvidia* /dev/dri/* >/dev/null 2>&1; then
    yellow "Some processes still use the GPU nodes."
    if [[ "${FORCE}" == "--force" ]]; then
      fuser -k /dev/nvidia* /dev/dri/* >/dev/null 2>&1 || true
    else
      red "Abort (use --force to kill them)."; exit 1
    fi
  fi
fi

# 5) Try to quiesce the driver
if command -v nvidia-smi >/dev/null 2>&1; then
  sudo nvidia-smi -pm 0 >/dev/null 2>&1 || true
  # GPU reset usually fails if it ever displayed, but try quietly
  sudo nvidia-smi --gpu-reset >/dev/null 2>&1 || true
fi

# 6) Unload modules (order matters)
unload_mod(){
  local m="$1"
  if lsmod | grep -q "^$m"; then
    sudo modprobe -r "$m" && echo "unloaded: $m" || yellow "could not unload: $m"
  fi
}
unload_mod nvidia_drm
unload_mod nvidia_modeset
unload_mod nvidia_uvm
unload_mod nvidia

# 7) Remove PCI functions (remove children first, GPU last)
# Typical order: .3 (UCSI) .2 (USB) .1 (HD Audio) .0 (VGA)
for fn in 3 2 1 0; do
  DEV="${BUS_PREFIX}.${fn}"
  if [[ -e "${SYSFS}/${DEV}" ]]; then
    echo 1 | sudo tee "${SYSFS}/${DEV}/remove" >/dev/null || true
    echo "removed: ${DEV}"
  fi
done

green "Safe to power off the eGPU enclosure and unplug the cable."
