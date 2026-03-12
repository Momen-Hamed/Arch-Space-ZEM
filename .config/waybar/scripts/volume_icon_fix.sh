#!/bin/bash
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
if [ -z "$volume" ]; then
    echo '{"text": "󰖁 ", "tooltip": "No output device"}'
    exit 0
fi

muted=$(echo "$volume" | grep -c "MUTED")
vol=$(echo "$volume" | awk '{print int($2 * 100)}')
[ "$vol" -gt 100 ] && vol=100

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

# Build tooltip starting with main volume
tooltip="Volume: ${vol}%"

# Loop through ALL stream nodes
while IFS= read -r stream_line; do
    stream_id=$(echo "$stream_line" | awk '{print $1}' | tr -d '.')
    app_name=$(echo "$stream_line" | sed 's/^[[:space:]]*[0-9]*\.[[:space:]]*//' | xargs)

    [ -z "$stream_id" ] && continue

    app_vol=$(wpctl get-volume "$stream_id" 2>/dev/null | awk '{print int($2 * 100)}')
    app_muted=$(wpctl get-volume "$stream_id" 2>/dev/null | grep -c "MUTED")

    [ -z "$app_vol" ] && continue

    if [ "$app_muted" -eq 1 ]; then
        tooltip=$(printf "%s\n%s: muted" "$tooltip" "$app_name")
    else
        tooltip=$(printf "%s\n%s: %s%%" "$tooltip" "$app_name" "$app_vol")
    fi
done < <(wpctl status 2>/dev/null | awk '/└─ Streams:/,/^[^ ]/' | grep "\." | grep -v "output\|input")

json_out=$(jq -cn \
    --arg text "$icon" \
    --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip}')
echo "$json_out"