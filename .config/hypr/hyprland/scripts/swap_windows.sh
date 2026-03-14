i#!/bin/bash
dir=$1
current=$(hyprctl activewindow -j | jq '.at')
cx=$(echo $current | jq '.[0]')
cy=$(echo $current | jq '.[1]')

leftmost=$(hyprctl clients -j | jq '[.[].at[0]] | min')
rightmost=$(hyprctl clients -j | jq '[.[].at[0]] | max')
topmost=$(hyprctl clients -j | jq '[.[].at[1]] | min')
bottommost=$(hyprctl clients -j | jq '[.[].at[1]] | max')

case $dir in
    l) [ "$cx" -eq "$leftmost" ] && hyprctl dispatch swapwindow r || hyprctl dispatch swapwindow l ;;
    r) [ "$cx" -eq "$rightmost" ] && hyprctl dispatch swapwindow l || hyprctl dispatch swapwindow r ;;
    u) [ "$cy" -eq "$topmost" ] && hyprctl dispatch swapwindow d || hyprctl dispatch swapwindow u ;;
    d) [ "$cy" -eq "$bottommost" ] && hyprctl dispatch swapwindow u || hyprctl dispatch swapwindow d ;;
esac
