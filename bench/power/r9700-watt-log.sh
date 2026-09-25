#!/usr/bin/env bash
# Log AMD Radeon AI PRO R9700 GPU power on gaming-b650. No root needed.
# Reads /sys/class/drm/card1/device/hwmon/hwmon7/power1_average (microwatts)
# and filters blank and spurious reads (the driver average sometimes spikes).
#
# Run on the host:            ./r9700-watt-log.sh [interval_s] [duration_s]
# Run from the workstation:   ssh 192.168.2.186 'bash -s' < r9700-watt-log.sh 0.5 60
# Output: CSV "ts_epoch,watt" on stdout. Summarize with awk after.
set -u
P="${GPU_POWER_PATH:-/sys/class/drm/card1/device/hwmon/hwmon7/power1_average}"
INT="${1:-1}"
DUR="${2:-60}"
end=$(( $(date +%s) + DUR ))
echo "ts_epoch,watt"
while [ "$(date +%s)" -lt "$end" ]; do
  uw=$(cat "$P" 2>/dev/null)
  case "$uw" in ''|*[!0-9]*) sleep "$INT"; continue ;; esac
  w=$(awk -v x="$uw" 'BEGIN{printf "%.1f", x/1000000}')
  # keep only physically plausible values (0 to 1000 W)
  if awk -v w="$w" 'BEGIN{exit !(w>=0 && w<=1000)}'; then
    echo "$(date +%s),$w"
  fi
  sleep "$INT"
done
