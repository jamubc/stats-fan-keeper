#!/bin/bash
# Re-applies the manual fan speed chosen in Stats after macOS (thermalmonitord) reclaims the fans.
# Runs as root via launchd every few seconds. Does nothing while Stats is closed or fans are on Auto.
SMC="/Applications/Stats.app/Contents/Resources/smc"

pgrep -xq Stats || exit 0
[ -x "$SMC" ] || exit 0

# Stats runs as the logged-in user, so read that user's saved fan settings.
user=$(stat -f %Su /dev/console)
home=$(dscl . -read "/Users/$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
PLIST="$home/Library/Preferences/eu.exelban.Stats.plist"
[ -f "$PLIST" ] || exit 0

status=$("$SMC" fans 2>/dev/null) || exit 0
count=$(awk '/^Number of fans:/{print int($4)}' <<<"$status")

for ((i = 0; i < ${count:-0}; i++)); do
  mode=$(/usr/libexec/PlistBuddy -c "Print :fan_${i}_mode" "$PLIST" 2>/dev/null)
  speed=$(/usr/libexec/PlistBuddy -c "Print :fan_${i}_speed" "$PLIST" 2>/dev/null)
  [ "$mode" = "1" ] && [ -n "$speed" ] || continue   # Stats has this fan on Auto

  current=$(awk -v f="^${i}:" '$0 ~ f {s=1} s && /^Mode:/ {print $2; exit}' <<<"$status")
  [ "$current" = "forced" ] && continue               # still under manual control

  # Setting a speed unlocks manual mode first (Ftst/F<i>Md) on Apple Silicon.
  "$SMC" fan "$i" -v "$speed" >/dev/null 2>&1 && logger -t stats-fan-keeper "fan $i reclaimed ($current), restored $speed rpm"
done
