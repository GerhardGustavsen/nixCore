#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: egpu <program> [args...]"
  exit 64
fi

# Export PRIME offload hints for NVIDIA + GLVND
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# If on X11 and xrandr is present, associate providers and set the exact NV provider name
if [[ -n "${DISPLAY-}" ]] && command -v xrandr >/dev/null 2>&1; then
  if xrandr --listproviders | grep -q 'NVIDIA'; then
    src=$(xrandr --listproviders | awk -F'name:' '/modesetting/{gsub(/^[ \t]+/,"",$2); print $2; exit}')
    nv=$(xrandr --listproviders | awk -F'name:' '/NVIDIA/{gsub(/^[ \t]+/,"",$2); print $2; exit}')
    if [[ -n "${src}" && -n "${nv}" ]]; then
      xrandr --setprovideroffloadsink "${src}" "${nv}" >/dev/null 2>&1 || true
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER="${nv}"
    fi
  fi
fi

prog="$1"

# Firefox quirks: on Xorg, force X/GLX; on Wayland sessions, allow Wayland
if [[ "${prog}" = "firefox" || "${prog}" = "firefox-bin" ]]; then
  case "${XDG_SESSION_TYPE-}" in
    x11|"") export MOZ_ENABLE_WAYLAND=0 ;;   # GLX path = respects GLVND vars
    wayland) export MOZ_ENABLE_WAYLAND=1 ;;  # Wayland/EGL path
  esac
  export MOZ_WEBRENDER=1
fi

# Keep GPU from deep-idle so nvidia-smi shows activity (ignore failure)
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi -pm 1 >/dev/null 2>&1 || true
fi

exec "$@"
