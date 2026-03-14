#!/bin/bash
while true; do
    COUNT=$(pgrep -x waybar | wc -l)
    if [ "$COUNT" -eq 0 ]; then
        waybar &
    elif [ "$COUNT" -gt 1 ]; then
        pkill waybar
        waybar &
    fi
done