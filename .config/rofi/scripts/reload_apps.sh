#!/usr/bin/env bash

echo "🎨 Generating theme with matugen..."
echo "✅ Matugen completed successfully"

## Helper Functions

kill_if_running() { pgrep -x "$1" >/dev/null && pkill -x "$1"; }

restart_service() {
    if pgrep -f "$1" >/dev/null; then
        pkill -f "$1"
        sleep 0.5
        $1 &>/dev/null &
    fi
}

has_window() {
    hyprctl clients -j | jq -e ".[] | select(.class == \"$1\")" >/dev/null 2>&1
}

## Reload Apps (Parallel Execution)

# Waybar
pkill waybar
waybar > /dev/null

# Kill only
kill_if_running waypaper

# Nautilus - only restart if it has a visible window
if has_window "org.gnome.Nautilus"; then
    pkill -x nautilus
    nautilus &>/dev/null &
else 
    pkill -x nautilus
fi

# Other GTK Apps
pgrep -x qalculate-gtk >/dev/null && { pkill -x qalculate-gtk; qalculate-gtk &>/dev/null & } &
pgrep -x pavucontrol >/dev/null && { pkill -x pavucontrol; pavucontrol &>/dev/null & } &
pgrep -x blueman-manager >/dev/null && { pkill -x blueman-manager; blueman-manager &>/dev/null & } &
pgrep -x evince >/dev/null && { pkill -x evince; evince &>/dev/null & } &
pgrep -x eog >/dev/null && { pkill -x eog; eog &>/dev/null & } &
pgrep -x gnome-calendar >/dev/null && { pkill -x gnome-calendar; gnome-calendar &>/dev/null & } &
pgrep -x gnome-weather >/dev/null && { pkill -x gnome-weather; gnome-weather &>/dev/null & } &
pgrep -x overskride >/dev/null && { pkill -x overskride; overskride &>/dev/null & } &
pgrep -x nm-connection-e >/dev/null && { pkill -x nm-connection-e; nm-connection-editor &>/dev/null & } &
pgrep -x file-roller >/dev/null && { pkill -x file-roller; file-roller &>/dev/null & } &
pgrep -f nmgui >/dev/null && { pkill -f nmgui; nmgui &>/dev/null & }
pgrep -x gnome-system-mo >/dev/null && { pkill -x gnome-system-mo; gnome-system-monitor &>/dev/null & } &

# GNOME Clocks - only restart if it has a visible window
if has_window "org.gnome.clocks"; then
    pkill -x gnome-clocks
    gnome-clocks &>/dev/null &
fi

# GNOME Text Editor (process name != binary name)
pgrep -x gnome-text-edit >/dev/null && { pkill -x gnome-text-edit; gnome-text-editor &>/dev/null & } &

# System Services (need delay to restart properly)
restart_service "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" &
restart_service "/usr/lib/xdg-desktop-portal-gtk" &

# Spotify
pgrep -x spotify >/dev/null && { spicetify config color_scheme dark && spicetify apply & }

#rsvg-convert -w 500 -h 250 /tmp/arch.svg -o ~/.config/fastfetch/arch.png
#magick -size 500x500 -density 300 /tmp/arch.svg -background none ~/.config/fastfetch/arch.png

#rsvg-convert -w 500 -h 500 /tmp/arch.svg -o ~/.config/fastfetch/arch.png

wait  # Wait for all background jobs to complete

echo "✅ Theme reload complete!"
