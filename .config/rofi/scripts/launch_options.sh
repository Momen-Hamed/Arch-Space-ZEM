#!/bin/bash

case "$1" in
    launcher)
        swaync-client --close-panel && rofi -show drun -show-icons -theme-str "textbox-prompt-colon { str: \"$(date '+%I:%M %p')\";} textbox-quote { str: '$(~/.config/rofi/scripts/quotes.sh)';}"
        ;;
    emoji)
        swaync-client --close-panel && rofimoji --selector rofi --action copy --clipboarder wl-copy --max-recent 0 --use-icons --selector-args "-theme $HOME/.config/rofi/launcher/n4zl\ theme/emoji/emoji.rasi"
        ;;
    clipboard)
        tmp_dir="/tmp/cliphist"
        rm -rf "$tmp_dir"

        if [[ -n "$2" ]]; then
            cliphist decode <<<"$2" | wl-copy
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
        ;;
    *)
        echo "Usage: $(basename "$0") [launcher|emoji|clipboard]"
        exit 1
        ;;
esac
