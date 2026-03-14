#!/bin/bash
CACHE_FILE="$HOME/.cache/hyprlock_weather_cache"  # persists across reboots
CACHE_TTL=600
LAT="21.49"
LON="39.19"
ICON_STYLE="nerd"
CONFIG_FILE="$HOME/.config/hypr/hyprlock.conf"
get_icon_nerd() {
local code=$1
case $code in
clearsky*)             echo "󰖙" ;;
fair*)                 echo "󰖕" ;;
partlycloudy*)         echo "󰖕" ;;
cloudy*)               echo "󰖔" ;;
fog*)                  echo "󰖑" ;;
rain*|drizzle*|sleet*) echo "󰖗" ;;
snow*)                 echo "󰖘" ;;
thunder*)              echo "󰖓" ;;
*)                     echo "󰖙" ;;
esac
}
get_icon_emoji() {
local code=$1
case $code in
clearsky*)             echo "☀️" ;;
fair*|partlycloudy*)   echo "⛅" ;;
cloudy*)               echo "☁️" ;;
fog*)                  echo "🌫️" ;;
rain*|drizzle*|sleet*) echo "🌧️" ;;
snow*)                 echo "❄️" ;;
thunder*)              echo "⛈️" ;;
*)                     echo "🌡️" ;;
esac
}
update_size() {
local digits=$1
local new_size
case $digits in
1) new_size="70, 45" ;;
2) new_size="81, 45" ;;
*) new_size="91, 45" ;;
esac
sed -i \
-e 's/size = 70, 45/size = '"$new_size"'/g' \
-e 's/size = 81, 45/size = '"$new_size"'/g' \
-e 's/size = 91, 45/size = '"$new_size"'/g' \
"$CONFIG_FILE"
}
fetch_weather() {
local url="https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${LAT}&lon=${LON}"
local data
    data=$(curl -sf --max-time 10 \
-H "User-Agent: hyprlock-weather/1.0 github.com/user/dotfiles" \
"$url" 2>/dev/null)
if [[ -z "$data" ]]; then
return
fi
local temp_c condition_code
    temp_c=$(echo "$data" | jq -r '.properties.timeseries[0].data.instant.details.air_temperature | round' | tr -dc '0-9-')
    condition_code=$(echo "$data" | jq -r '.properties.timeseries[0].data.next_1_hours.summary.symbol_code // .properties.timeseries[0].data.next_6_hours.summary.symbol_code')
local icon
if [[ "$ICON_STYLE" == "nerd" ]]; then
        icon=$(get_icon_nerd "$condition_code")
else
        icon=$(get_icon_emoji "$condition_code")
fi
local stripped digits
    stripped=$(echo "$temp_c" | tr -d '-')
    digits=${#stripped}
update_size "$digits"
echo "${icon}  ${temp_c}°" > "$CACHE_FILE"
echo "$(date +%s)" >> "$CACHE_FILE"
}
use_cache=false
if [[ -f "$CACHE_FILE" ]]; then
    cached_output=$(sed -n '1p' "$CACHE_FILE")
    cached_time=$(sed -n '2p' "$CACHE_FILE")
    current_time=$(date +%s)
if (( current_time - cached_time < CACHE_TTL )); then
        use_cache=true
fi
fi
if $use_cache; then
    echo "$cached_output"
    if (( current_time - cached_time > CACHE_TTL / 2 )); then
        fetch_weather &
    fi
else
    if [[ -n "$cached_output" ]]; then
        echo "$cached_output"
        fetch_weather &
    else
        fetch_weather
        cached_output=$(sed -n '1p' "$CACHE_FILE" 2>/dev/null)
        echo "${cached_output:-󰖙  --°}"
    fi
fi