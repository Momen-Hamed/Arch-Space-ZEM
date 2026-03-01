#!/bin/bash
RULES="$HOME/.config/hypr/hyprland/rules.conf"

sed -i 's/layerrule = match:namespace rofi, animation slide bottom/layerrule = match:namespace rofi, animation slide left/' "$RULES"

pkill -x rofi || rofimoji --selector rofi --action copy --clipboarder wl-copy --max-recent 0 --use-icons --selector-args "-theme $HOME/.config/rofi/launcher/n4zl\ theme/emoji/emoji.rasi"

