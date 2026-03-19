#!/bin/bash

RULES="$HOME/.config/hypr/hyprland/rules.conf"

sed -i 's/layerrule = match:namespace rofi, animation slide bottom/layerrule = match:namespace rofi, blur on, animation slide right/g' "$RULES"

selected_option=$(printf "Shutdown\x00icon\x1f${HOME}/.config/rofi/icons/power.png
Reboot\x00icon\x1f${HOME}/.config/rofi/icons/restart.png
Windows\x00icon\x1f${HOME}/.config/rofi/icons/windows.png
Hibernate\x00icon\x1f${HOME}/.config/rofi/icons/hibernate.png
Logout\x00icon\x1f${HOME}/.config/rofi/icons/logout.png
Lock\x00icon\x1f${HOME}/.config/rofi/icons/lock.png" | rofi -dmenu \
    -i \
    -no-sort \
    -theme-str "textbox-prompt-colon { str:  \" 󰄉   Uptime: $(uptime -p | sed 's/up //')\";}" \
    -p "Power" \
    -theme "~/.config/rofi/menus/powermenu/powermenu.rasi")

sed -i 's/layerrule = match:namespace rofi, blur on, animation slide right/layerrule = match:namespace rofi, animation slide bottom/g' "$RULES"

if [ "$selected_option" == "Lock" ]; then
    playerctl -a pause; hyprlock
elif [ "$selected_option" == "Logout" ]; then
    hyprctl dispatch exit
elif [ "$selected_option" == "Shutdown" ]; then
    poweroff
elif [ "$selected_option" == "Reboot" ]; then
    reboot
elif [ "$selected_option" == "Hibernate" ]; then
    systemctl hibernate
elif [ "$selected_option" == "Windows" ]; then
   sudo ~/.local/bin/reboot_windows.sh
else
    echo "No match"
fi
