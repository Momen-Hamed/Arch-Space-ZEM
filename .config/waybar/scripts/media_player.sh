#!/bin/bash

# Ignore these players
IGNORED_PLAYERS=("kdeconnect")

# Player icons
declare -A PLAYER_ICONS=(
    ["spotify"]="󰓇"
    ["mpv"]="󰐊"
    ["vlc"]="󰕼"
    ["rhythmbox"]="󰓃"
    ["firefox"]="󰈹"
    ["chromium"]="󰊯"
    ["brave"]="󰖟"
    ["default"]="󰝚"
)

# Get all active players
players=$(playerctl -l 2>/dev/null)

if [[ -z "$players" ]]; then
    echo '{"text": "󰝚   Nothing is playing", "class": "idle"}'
    exit
fi

# Find the best active player (playing first, then paused)
active_player=""
for player in $players; do
    skip=false
    for ignored in "${IGNORED_PLAYERS[@]}"; do
        if [[ "$player" == *"$ignored"* ]]; then
            skip=true
            break
        fi
    done
    $skip && continue

    status=$(playerctl -p "$player" status 2>/dev/null)
    if [[ "$status" == "Playing" ]]; then
        active_player="$player"
        break
    elif [[ "$status" == "Paused" && -z "$active_player" ]]; then
        active_player="$player"
    fi
done

if [[ -z "$active_player" ]]; then
    echo '{"text": "󰝚   Nothing is playing", "class": "idle"}'
    exit
fi

# ── Volume control (called with "up" or "down" argument) ──────────────────────
if [[ "$1" == "up" || "$1" == "down" ]]; then
    player_name=$(echo "$active_player" | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')

    # Map playerctl names to wpctl stream names
    declare -A WPCTL_NAMES=(
        ["firefox"]="zen"
        ["chromium"]="chromium"
        ["brave"]="brave"
        ["spotify"]="spotify"
        ["mpv"]="mpv"
        ["vlc"]="vlc"
    )
    wpctl_name="${WPCTL_NAMES[$player_name]:-$player_name}"

    # Find the PipeWire stream node ID
    NODE_ID=$(wpctl status | grep -i "$wpctl_name" | grep -o '[0-9]\+\.' | tr -d '.' | tail -1)

    if [[ -z "$NODE_ID" ]]; then
        echo "Could not find PipeWire node for $wpctl_name" >&2
        exit 1
    fi

    [[ "$1" == "up" ]]   && wpctl set-volume -l 1 "$NODE_ID" 5%+
    [[ "$1" == "down" ]] && wpctl set-volume "$NODE_ID" 5%-
    exit
fi

# ── Normal status output ──────────────────────────────────────────────────────
status=$(playerctl -p "$active_player" status 2>/dev/null)
title=$(playerctl -p "$active_player" metadata title 2>/dev/null)
artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)

# Get player base name (spotify.instance1 -> spotify)
player_name=$(echo "$active_player" | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')

# Pick player icon
player_icon="${PLAYER_ICONS[$player_name]:-${PLAYER_ICONS[default]}}"

# Status icon
if [[ "$status" == "Playing" ]]; then
    status_icon=""
    class="playing"
else
    status_icon=""
    class="paused"
fi

# Truncate long titles
max_length=35
if [[ ${#title} -gt $max_length ]]; then
    title="${title:0:$max_length}..."
fi

# Build text
if [[ -n "$artist" ]]; then
    text="$status_icon  $artist - $title"
else
    text="$status_icon  $title"
fi

echo "{\"text\": \"$text\", \"class\": \"$class\", \"tooltip\": \"$active_player\"}"