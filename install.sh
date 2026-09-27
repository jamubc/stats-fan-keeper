#!/bin/bash
set -e
cd "$(dirname "$0")"
sudo mkdir -p /usr/local/bin
sudo install -m 755 -o root -g wheel stats-fan-keeper.sh /usr/local/bin/stats-fan-keeper.sh
sudo install -m 644 -o root -g wheel io.github.jamubc.stats-fan-keeper.plist /Library/LaunchDaemons/io.github.jamubc.stats-fan-keeper.plist
sudo launchctl bootout system/io.github.jamubc.stats-fan-keeper 2>/dev/null || true
sudo launchctl bootstrap system /Library/LaunchDaemons/io.github.jamubc.stats-fan-keeper.plist
echo "installed. Watch it with: log stream --predicate 'eventMessage CONTAINS \"stats-fan-keeper\"'"
