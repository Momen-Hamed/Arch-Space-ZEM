#!/usr/bin/env bash
# Hyprland System Sounds Daemon
# Requirements: libcanberra, canberra-gtk-play, networkmanager, socat

play() {
    # Play standard sound by name
    canberra-gtk-play -i "$1" &
}

# ── USB device plug/unplug ─────────────────────────────
udevadm monitor --udev --subsystem-match=usb --property | while read -r line; do
    if [[ "$line" =~ ^ACTION=add$ ]]; then
        play "message-new-instant"
    elif [[ "$line" =~ ^ACTION=remove$ ]]; then
        play "window-attention"
    fi
done &

# ── Power plug/unplug ────────────────────────────────
prev_power=""
while true; do
    status=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0)
    if [[ "$status" != "$prev_power" ]]; then
        if [[ "$status" == "1" ]]; then
            play "button-pressed"        # plugged in
        else
            play "window-attention"      # unplugged
        fi
        prev_power="$status"
    fi
    sleep 2
done &

# ── Network connectivity ─────────────────────────────
prev_net=""
while true; do
    if nmcli -t -f STATE general 2>/dev/null | grep -q "connected"; then
        net="connected"
    else
        net="disconnected"
    fi

    if [[ "$net" != "$prev_net" ]]; then
        if [[ "$net" == "connected" ]]; then
            play "message-new-instant"
        elif [[ "$prev_net" == "connected" ]]; then
            play "window-attention"
        fi
        prev_net="$net"
    fi
    sleep 3
done &

# ── Hyprland socket events ───────────────────────────
if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    HYPR_SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    if [[ -e "$HYPR_SOCKET" ]]; then
        socat -U - "UNIX-CONNECT:$HYPR_SOCKET" 2>/dev/null | while IFS= read -r line; do
            event="${line%%>>*}"
            case "$event" in
                urgent)
                    play "window-attention"
                    ;;
                notification)
                    play "message-new-instant"
                    ;;
            esac
        done &
    fi
fi

wait