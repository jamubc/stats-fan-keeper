#!/bin/bash
sudo launchctl bootout system/io.github.jamubc.stats-fan-keeper 2>/dev/null
sudo rm -f /Library/LaunchDaemons/io.github.jamubc.stats-fan-keeper.plist /usr/local/bin/stats-fan-keeper.sh
echo removed
