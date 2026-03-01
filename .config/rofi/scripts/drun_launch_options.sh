#!/bin/bash
RULES="$HOME/.config/hypr/hyprland/rules.conf"

sed -i 's/layerrule = match:namespace rofi, animation slide left/layerrule = match:namespace rofi, animation slide bottom/' "$RULES"

pkill rofi || rofi -show drun -show-icons -theme-str "textbox-prompt-colon { str: \"$(date '+%I:%M %p')\";} textbox-quote { str: '$(~/.config/rofi/scripts/quotes.sh)';}"

