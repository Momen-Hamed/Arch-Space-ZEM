#!/bin/bash
pkill slurp 2>/dev/null
pkill hyprpicker 2>/dev/null
pgrep grim && pkill grim; true

# Always clean up on exit
trap "pkill slurp 2>/dev/null; pkill hyprpicker 2>/dev/null" EXIT

FILE=~/Pictures/Screenshots/$(date '+%y-%d:%m-%H:%M').png
SUCCESS=false

if [ "$1" = "region" ]; then
    pgrep slurp && exit 0
    hyprpicker -r -z &
    HYPRPICKER_PID=$!
    sleep 0.2
    REGION=$(hyprctl clients -j | jq -r --argjson ws "$(hyprctl activeworkspace -j | jq '.id')" '.[] | select(.workspace.id == $ws) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp -d)
    if [ -z "$REGION" ]; then kill $HYPRPICKER_PID 2>/dev/null; exit 0; fi
    kill $HYPRPICKER_PID 2>/dev/null
    grim -g "$REGION" "$FILE" && wl-copy < "$FILE" && SUCCESS=true
elif [ "$1" = "all" ]; then
    pgrep slurp && exit 0
    grim "$FILE" && wl-copy < "$FILE" && SUCCESS=true
elif [ "$1" = "full" ]; then
    pgrep slurp && exit 0
    MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
    grim -o "$MONITOR" "$FILE" && wl-copy < "$FILE" && SUCCESS=true
fi
if [ "$SUCCESS" = false ] || [ ! -f "$FILE" ]; then
    exit 0
fi
ACTION=$(notify-send -i camera "Screenshot taken" -a "Screenshot" \
    --action="view=View Screenshot" \
    --action="edit=Edit Screenshot" \
    --wait)
if [ "$ACTION" = "view" ]; then
    eog "$FILE"
elif [ "$ACTION" = "edit" ]; then
    satty --filename "$FILE"
fi
