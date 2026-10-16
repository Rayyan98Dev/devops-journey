#!/usr/bin/env bash
# heartbeat.sh: print a line every 10 seconds
while true; do
    echo "heartbeat: $(date +%T)"
    sleep 10
done