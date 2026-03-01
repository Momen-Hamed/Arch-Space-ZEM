#!/bin/bash

RULES="$HOME/.config/hypr/hyprland/rules.conf"
tmp_dir="/tmp/cliphist"
rm -rf "$tmp_dir"

if [[ -n "$1" ]]; then
    cliphist decode <<<"$1" | wl-copy
    exit
fi

mkdir -p "$tmp_dir"

read -r -d '' prog <<EOF
/^[0-9]+\s<meta http-equiv=/ { next }
match(\$0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)/, grp) {
    system("echo " grp[1] "\\\\\t | cliphist decode >$tmp_dir/"grp[1]"."grp[3])
    print \$0"\0icon\x1f$tmp_dir/"grp[1]"."grp[3]
    next
}
1
EOF
sed -i 's/layerrule = match:namespace rofi, animation slide left/layerrule = match:namespace rofi, animation slide bottom/' "$RULES"

chosen=$(cliphist list | gawk "$prog" | rofi -display-columns 2 -p "Clipboard" \
-kb-custom-1 "alt+w" \
-theme "$HOME/.config/rofi/launcher/n4zl theme/clipboard/clipboard.rasi" \
-dmenu)
exit_code=$?

if [[ $exit_code -eq 10 ]]; then
    cliphist wipe
    notify-send "Clipboard cleared"
elif [[ -n "$chosen" ]]; then
    cliphist decode <<<"$chosen" | wl-copy
fi