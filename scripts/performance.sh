#!/usr/bin/env bash
# performance.sh — flip performance knobs when entering/leaving "performance" mode
# Usage: performance.sh enable|disable
set -euo pipefail

ACTION="${1:-}"; [[ "$ACTION" == "enable" || "$ACTION" == "disable" ]] || { echo "usage: $0 {enable|disable}"; exit 2; }

# --- tiny logger ---
RED=$'\033[91m'; YELLOW=$'\033[93m'; GREEN=$'\033[92m'; RESET=$'\033[0m'
info() { printf '%s\n' "$*"; }
warn() { printf "${YELLOW}⚠ %s${RESET}\n" "$*" >&2; }
err()  { printf "${RED}ERROR:${RESET} %s\n" "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }
asroot() {
  sudo -n true 2>/dev/null || warn "sudo may prompt for password"
  sudo "$@"
}

# --- summary collector ---
SUMMARY=()
addsum() { SUMMARY+=("$1"); }

# --- helpers ---
run() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    info "OK: $desc"
    return 0
  else
    warn "Failed: $desc"
    return 1
  fi
}
sysfs_write() {
  local path="$1" val="$2" desc="$3"
  if [[ -e "$path" ]]; then
    if echo "$val" | asroot tee "$path" >/dev/null 2>&1; then
      info "OK: $desc"
      return 0
    else
      warn "Failed: $desc ($path)"
      return 1
    fi
  else
    warn "Missing: $desc ($path)"
    return 1
  fi
}

# --- CPU ---
choose_governor() { # usage: choose_governor /sys/.../policyX -> prints best governor
  local govs_file="$1/scaling_available_governors"
  if [[ -r "$govs_file" ]]; then
    local avail; avail="$(<"$govs_file")"
    # preference order for disable (balanced-ish)
    for g in schedutil powersave conservative ondemand; do
      [[ " $avail " == *" $g "* ]] && { printf '%s' "$g"; return 0; }
    done
    # fall back to whatever is listed first
    set -- $avail; printf '%s' "$1"
  else
    # file missing: guess a safe fallback
    printf '%s' powersave
  fi
}

enable_cpu() {
  local gov_changed=0 gov_total=0
  if have powerprofilesctl; then
    run "power profile → performance" powerprofilesctl set performance || true
    addsum "CPU profile: performance"
  else
    addsum "CPU profile: unavailable"
  fi

  # Try to set "performance" if available, else best-high governor we can find
  for p in /sys/devices/system/cpu/cpufreq/policy*; do
    [[ -e "$p/scaling_governor" ]] || continue
    gov_total=$((gov_total+1))
    local target="performance"
    if [[ -r "$p/scaling_available_governors" ]]; then
      avail="$(<"$p/scaling_available_governors")"
      if [[ " $avail " != *" performance "* ]]; then
        # fall back to common high-performance governors (rarely needed)
        for g in performance; do :; done
      fi
    fi
    if echo "$target" | asroot tee "$p/scaling_governor" >/dev/null 2>&1; then
      info "OK: CPU governor ${p##*/} → $target"
      gov_changed=$((gov_changed+1))
    else
      warn "Failed: CPU governor ${p##*/} → $target"
    fi
  done
  addsum "CPU governor: performance (${gov_changed}/${gov_total})"

  if sysfs_write /sys/devices/system/cpu/intel_pstate/no_turbo 0 "Intel Turbo → enabled (0)"; then
    addsum "Intel Turbo: enabled"
  else
    addsum "Intel Turbo: unchanged/not present"
  fi

  if have sysctl && asroot sysctl -q vm.swappiness=10 >/dev/null 2>&1; then
    info "OK: vm.swappiness → 10"
    addsum "Swappiness: 10"
  else
    addsum "Swappiness: unchanged"
  fi
}

disable_cpu() {
  if have powerprofilesctl; then
    powerprofilesctl set balanced >/dev/null 2>&1 || true
    addsum "CPU profile: balanced"
  else
    addsum "CPU profile: unavailable"
  fi

  local gov_changed=0 gov_total=0
  for p in /sys/devices/system/cpu/cpufreq/policy*; do
    [[ -e "$p/scaling_governor" ]] || continue
    gov_total=$((gov_total+1))
    target="$(choose_governor "$p")"
    if echo "$target" | asroot tee "$p/scaling_governor" >/dev/null 2>&1; then
      info "OK: CPU governor ${p##*/} → $target"
      gov_changed=$((gov_changed+1))
    else
      warn "Failed: CPU governor ${p##*/} → $target"
    fi
  done
  addsum "CPU governor: reverted (${gov_changed}/${gov_total})"

  if echo 1 | asroot tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null 2>&1; then
    info "OK: Intel Turbo → disabled (1)"
    addsum "Intel Turbo: disabled"
  else
    addsum "Intel Turbo: unchanged/not present"
  fi

  if have sysctl && asroot sysctl -q vm.swappiness=60 >/dev/null 2>&1; then
    info "OK: vm.swappiness → 60"
    addsum "Swappiness: 60"
  else
    addsum "Swappiness: unchanged"
  fi
}


# --- GPU ---
enable_gpu() {
  local nvidia_present=0 amdgpu_cnt=0 amdgpu_total=0

  if have nvidia-smi; then
    nvidia_present=1
    run "NVIDIA persistence mode ON"  asroot nvidia-smi -pm 1 || true
    run "NVIDIA app clocks unrestricted" asroot nvidia-smi -acp UNRESTRICTED || true
    run "NVIDIA reset app clocks" asroot nvidia-smi -rgc || true
    run "NVIDIA allow driver-boost (lgc 0,0)" asroot nvidia-smi -lgc 0,0 || true
    addsum "NVIDIA: persistence/boost enabled"
  fi

  for f in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
    [[ -e "$f" ]] || continue
    amdgpu_total=$((amdgpu_total+1))
    if echo performance | asroot tee "$f" >/dev/null 2>&1; then
      info "OK: ${f%/device/*} perf → performance"
      amdgpu_cnt=$((amdgpu_cnt+1))
    else
      warn "Failed: ${f%/device/*} perf → performance"
    fi
  done
  if (( amdgpu_total > 0 )); then
    addsum "AMDGPU perf level: performance (${amdgpu_cnt}/${amdgpu_total})"
  elif (( nvidia_present == 0 )); then
    addsum "GPU accelerator: not detected"
  fi
}
disable_gpu() {
  local amdgpu_cnt=0 amdgpu_total=0

  if have nvidia-smi; then
    asroot nvidia-smi -rac >/dev/null 2>&1 || true
    asroot nvidia-smi -pm 0  >/dev/null 2>&1 || true
    info "OK: NVIDIA app clocks reset; persistence OFF"
    addsum "NVIDIA: persistence off, clocks reset"
  fi

  for f in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
    [[ -e "$f" ]] || continue
    amdgpu_total=$((amdgpu_total+1))
    if echo auto | asroot tee "$f" >/dev/null 2>&1; then
      info "OK: ${f%/device/*} perf → auto"
      amdgpu_cnt=$((amdgpu_cnt+1))
    else
      warn "Failed: ${f%/device/*} perf → auto"
    fi
  done
  if (( amdgpu_total > 0 )); then
    addsum "AMDGPU perf level: auto (${amdgpu_cnt}/${amdgpu_total})"
  fi
}

# --- I/O schedulers ---
enable_io() {
  local nv_cnt=0 nv_tot=0 sd_cnt=0 sd_tot=0
  for s in /sys/block/nvme*/queue/scheduler; do
    [[ -e "$s" ]] || continue
    nv_tot=$((nv_tot+1))
    if echo none | asroot tee "$s" >/dev/null 2>&1; then
      info "OK: ${s%/queue/*} scheduler → none"
      nv_cnt=$((nv_cnt+1))
    else
      warn "Failed: ${s%/queue/*} scheduler → none"
    fi
  done
  for s in /sys/block/sd*/queue/scheduler; do
    [[ -e "$s" ]] || continue
    sd_tot=$((sd_tot+1))
    if grep -q 'mq-deadline' "$s" && echo mq-deadline | asroot tee "$s" >/dev/null 2>&1; then
      info "OK: ${s%/queue/*} scheduler → mq-deadline"
      sd_cnt=$((sd_cnt+1))
    fi
  done
  (( nv_tot>0 )) && addsum "NVMe sched: none (${nv_cnt}/${nv_tot})"
  (( sd_tot>0 )) && addsum "SATA sched: mq-deadline (${sd_cnt}/${sd_tot})"
}
disable_io() {
  local nv_cnt=0 nv_tot=0 sd_bfq=0 sd_cfq=0 sd_tot=0
  for s in /sys/block/nvme*/queue/scheduler; do
    [[ -e "$s" ]] || continue
    nv_tot=$((nv_tot+1))
    if echo none | asroot tee "$s" >/dev/null 2>&1; then
      info "OK: ${s%/queue/*} scheduler → none"
      nv_cnt=$((nv_cnt+1))
    else
      warn "Failed: ${s%/queue/*} scheduler → none"
    fi
  done
  for s in /sys/block/sd*/queue/scheduler; do
    [[ -e "$s" ]] || continue
    sd_tot=$((sd_tot+1))
    if grep -q 'bfq' "$s" && echo bfq | asroot tee "$s" >/dev/null 2>&1; then
      info "OK: ${s%/queue/*} scheduler → bfq"
      sd_bfq=$((sd_bfq+1))
    elif grep -q 'cfq' "$s" && echo cfq | asroot tee "$s" >/dev/null 2>&1; then
      info "OK: ${s%/queue/*} scheduler → cfq"
      sd_cfq=$((sd_cfq+1))
    fi
  done
  (( nv_tot>0 )) && addsum "NVMe sched: none (${nv_cnt}/${nv_tot})"
  if (( sd_tot>0 )); then
    if   (( sd_bfq>0 )); then addsum "SATA sched: bfq (${sd_bfq}/${sd_tot})"
    elif (( sd_cfq>0 )); then addsum "SATA sched: cfq (${sd_cfq}/${sd_tot})"
    else addsum "SATA sched: unchanged"
    fi
  fi
}

# --- conflicting daemons ---
enable_misc() {
  local stopped=()
  if have systemctl; then
    systemctl is-active --quiet tlp.service                      && { run "stop tlp" asroot systemctl stop tlp.service || true; stopped+=("tlp"); }
    systemctl is-active --quiet power-profiles-daemon.service    && { run "stop power-profiles-daemon" asroot systemctl stop power-profiles-daemon.service || true; stopped+=("power-profiles-daemon"); }
    systemctl is-active --quiet auto-cpufreq.service             && { run "stop auto-cpufreq" asroot systemctl stop auto-cpufreq.service || true; stopped+=("auto-cpufreq"); }
  fi
  (( ${#stopped[@]} )) && addsum "Power daemons: stopped (${stopped[*]})" || addsum "Power daemons: none running"
}
disable_misc() {
  local started=()
  if have systemctl; then
    asroot systemctl start power-profiles-daemon.service >/dev/null 2>&1 && started+=("power-profiles-daemon") || true
    asroot systemctl start tlp.service >/dev/null 2>&1 && started+=("tlp") || true
  fi
  (( ${#started[@]} )) && addsum "Power daemons: started (${started[*]})" || addsum "Power daemons: none started"
}

# --- dispatcher ---
if [[ "$ACTION" == "enable" ]]; then
  info "Enabling performance knobs…"
  enable_misc
  enable_cpu
  #enable_gpu
  enable_io
  echo
  echo "Performance features activated:"
  printf '  - %s\n' "${SUMMARY[@]}"
  echo
  exit 0
else
  info "Disabling performance knobs…"
  disable_io
  #disable_gpu
  disable_cpu
  disable_misc
  echo
  echo "Performance features deactivated:"
  printf '  - %s\n' "${SUMMARY[@]}"
  echo
  exit 0
fi
