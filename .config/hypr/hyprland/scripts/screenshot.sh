#!/bin/bash

FILE=~/Pictures/Screenshots/$(date '+%y-%d:%m-%H:%M').png

if [ "$1" = "region" ]; then
    pgrep slurp && exit 0
    grimblast --freeze copysave area "$FILE"
    if [ $? -ne 0 ] || [ ! -f "$FILE" ]; then
        pkill -x grim 2>/dev/null
        exit 0
    fi
else
    grimblast copysave screen "$FILE"
    if [ $? -ne 0 ] || [ ! -f "$FILE" ]; then
        pkill -x grim 2>/dev/null
        exit 0
    fi
fi

ACTION=$(notify-send "Screenshot taken" -i "$FILE" -a "Screenshot" \
    --action="view=View Screenshot" \
    --action="edit=Edit Screenshot" \
    --wait)

if [ "$ACTION" = "view" ]; then
    eog "$FILE"
elif [ "$ACTION" = "edit" ]; then
    satty --filename "$FILE"
fi