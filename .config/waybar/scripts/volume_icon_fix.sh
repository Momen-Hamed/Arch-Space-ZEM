#!/bin/bash
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

if [ -z "$volume" ]; then
    echo '{"text": "󰖁 ", "tooltip": "No output device"}'
    exit 0
fi

muted=$(echo "$volume" | grep -c "MUTED")
vol=$(echo "$volume" | awk '{print int($2 * 100)}')
[ "$vol" -gt 100 ] && vol=100

# Get active program and its volume from Streams section
stream_line=$(wpctl status 2>/dev/null | awk '/└─ Streams:/,/^[^ ]/' | grep "\." | grep -v "output\|input" | head -1)
app_name=$(echo "$stream_line" | sed 's/^[[:space:]]*[0-9]*\.[[:space:]]*//' | xargs)

# Get stream volume
stream_id=$(wpctl status 2>/dev/null | awk '/└─ Streams:/,/^[^ ]/' | grep "\." | grep -v "output\|input" | head -1 | awk '{print $1}' | tr -d '.')
app_vol=""
if [ -n "$stream_id" ]; then
    app_vol=$(wpctl get-volume "$stream_id" 2>/dev/null | awk '{print int($2 * 100)}')
fi

if [ "$muted" -eq 1 ]; then
    icon="󰝟 "
elif [ "$vol" -eq 0 ]; then
    icon="󰖁 "
elif [ "$vol" -lt 30 ]; then
    icon="󰕿 "
elif [ "$vol" -lt 70 ]; then
    icon="󰖀 "
else
    icon="󰕾 "
fi

if [ -n "$app_name" ] && [ -n "$app_vol" ]; then
    tooltip=$(printf "Volume: %s%%\n%s: %s%%" "$vol" "$app_name" "$app_vol")
elif [ -n "$app_name" ]; then
    tooltip=$(printf "Volume: %s%%\n%s" "$vol" "$app_name")
else
    tooltip=$(printf "Volume: %s%%" "$vol")
fi

json_out=$(jq -cn \
    --arg text "$icon" \
    --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip}')

echo "$json_out"