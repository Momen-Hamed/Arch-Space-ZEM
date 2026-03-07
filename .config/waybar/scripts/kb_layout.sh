#!/bin/bash
LAYOUT_FILE="/tmp/kb_layout"

keyboard=$(hyprctl devices -j | jq '
.keyboards
| ( map(select(.main == true)) | .[0] )
  // ( map(select(.active_keymap != null)) | .[0] )
  // .[0]
')

[ -z "$keyboard" ] && exit 0

if echo "$keyboard" | jq -e '.keymap_names' >/dev/null 2>&1; then
    active=$(echo "$keyboard" | jq -r '.active_layout // 0')
    mapfile -t layouts <<< "$(echo "$keyboard" | jq -r '.keymap_names[]')"
    layout="${layouts[$active]}"
else
    layout=$(echo "$keyboard" | jq -r '.active_keymap // ""')
fi

[ -z "$layout" ] && exit 0

echo "$layout" > "$LAYOUT_FILE"

case "$layout" in
    *Arabic*)   echo "󰌌  AR" ;;
    *English*)  echo "󰌌  EN" ;;
    *)          echo "󰌌  $(echo "${layout:0:2}" | tr '[:lower:]' '[:upper:]')" ;;
esac