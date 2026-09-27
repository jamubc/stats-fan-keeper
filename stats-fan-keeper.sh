#!/bin/bash
# Re-applies the manual fan speed chosen in Stats after macOS (thermalmonitord) reclaims the fans.
# Runs as root via launchd every few seconds. Does nothing while Stats is closed or fans are on Auto.
SMC="/Applications/Stats.app/Contents/Resources/smc"
STATS_TEAM="RP2S87B72W"

pgrep -xq Stats || exit 0
[ -x "$SMC" ] || exit 0

# The app bundle is usually user-writable; only run smc as root if it is still signed by Stats' developer.
codesign --verify -R="anchor apple generic and certificate leaf[subject.OU] = \"$STATS_TEAM\"" "$SMC" 2>/dev/null || {
  logger -t stats-fan-keeper "smc signature check failed, skipping"
  exit 0
}

# Read Stats' settings through the logged-in user's cfprefsd, not the plist on disk,
# which can lag behind for a few seconds after switching a fan back to Auto.
user=$(stat -f %Su /dev/console)
uid=$(id -u "$user" 2>/dev/null) || exit 0
pref() { launchctl asuser "$uid" sudo -u "$user" defaults read eu.exelban.Stats "$1" 2>/dev/null; }

status=$("$SMC" fans 2>/dev/null) || exit 0
count=$(awk '/^Number of fans:/{print int($4)}' <<<"$status")

for ((i = 0; i < ${count:-0}; i++)); do
  mode=$(pref "fan_${i}_mode")
  speed=$(pref "fan_${i}_speed")
  [ "$mode" = "1" ] && [ -n "$speed" ] || continue   # Stats has this fan on Auto

  fan=$(awk -v f="^${i}:" '$0 ~ f {s=1} s {print} s && /^Mode:/ {exit}' <<<"$status")
  current=$(awk '/^Mode:/{print $2}' <<<"$fan")
  min=$(awk '/^Minimal speed:/{print int($3)}' <<<"$fan")
  [ "$current" = "forced" ] && continue               # still under manual control

  # Never hold a fan below its minimum (e.g. Stats' "off" mode) against macOS reclaiming it.
  if [ "${speed%.*}" -lt "${min:-0}" ]; then
    continue
  fi

  # Setting a speed unlocks manual mode first (Ftst/F<i>Md) on Apple Silicon.
  "$SMC" fan "$i" -v "$speed" >/dev/null 2>&1 && logger -t stats-fan-keeper "fan $i reclaimed ($current), restored $speed rpm"
done
