#!/bin/bash
CACHE_FILE="/tmp/waybar_weather_cache"
CACHE_TTL=600

LAT="21.49"
LON="39.19"
ICON_STYLE="nerd"

get_icon_nerd() {
    local code=$1
    case $code in
        clearsky*)           echo "󰖙" ;;
        fair*)               echo "󰖕" ;;
        partlycloudy*)       echo "󰖕" ;;
        cloudy*)             echo "󰖔" ;;
        fog*)                echo "󰖑" ;;
        rain*|drizzle*|sleet*) echo "󰖗" ;;
        snow*)               echo "󰖘" ;;
        thunder*)            echo "󰖓" ;;
        *)                   echo "󰖙" ;;
    esac
}

get_condition_text() {
    local code=$1
    case $code in
        clearsky_day)        echo "Clear sky" ;;
        clearsky_night)      echo "Clear sky" ;;
        fair_day)            echo "Mainly clear" ;;
        fair_night)          echo "Mainly clear" ;;
        partlycloudy_day)    echo "Partly cloudy" ;;
        partlycloudy_night)  echo "Partly cloudy" ;;
        cloudy)              echo "Overcast" ;;
        fog)                 echo "Foggy" ;;
        lightrain*)          echo "Light rain" ;;
        rain)                echo "Rain" ;;
        heavyrain*)          echo "Heavy rain" ;;
        drizzle*)            echo "Drizzle" ;;
        sleet*)              echo "Sleet" ;;
        lightsnow*)          echo "Light snow" ;;
        snow)                echo "Snow" ;;
        heavysnow*)          echo "Heavy snow" ;;
        thunder*)            echo "Thunderstorm" ;;
        *)                   echo "$code" ;;
    esac
}

fetch_weather() {
    local url="https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${LAT}&lon=${LON}"
    local data
    data=$(curl -sf --max-time 10 \
        -H "User-Agent: waybar-weather/1.0 github.com/user/dotfiles" \
        "$url" 2>/dev/null)

    if [[ -z "$data" ]]; then
        printf '{"text": "󰖙  --°", "tooltip": "Weather unavailable", "class": "unknown"}\n'
        return
    fi

    local temp_c feels_like wind_speed humidity condition_code
    temp_c=$(echo "$data"      | jq -r '.properties.timeseries[0].data.instant.details.air_temperature | round')
    feels_like=$(echo "$data"  | jq -r '.properties.timeseries[0].data.instant.details.air_temperature | round')
    wind_speed=$(echo "$data"  | jq -r '.properties.timeseries[0].data.instant.details.wind_speed | . * 3.6 | round')
    humidity=$(echo "$data"    | jq -r '.properties.timeseries[0].data.instant.details.relative_humidity | round')
    condition_code=$(echo "$data" | jq -r '.properties.timeseries[0].data.next_1_hours.summary.symbol_code // .properties.timeseries[0].data.next_6_hours.summary.symbol_code')

    temp_c=$(echo "$temp_c" | tr -dc '0-9-')

    local icon
    icon=$(get_icon_nerd "$condition_code")

    local condition_text
    condition_text=$(get_condition_text "$condition_code")

    local text="${icon}  ${temp_c}°"
    local tooltip
    tooltip=$(printf "%s  %s\n\nTemperature:  %s°C\nFeels like:    %s°C\nHumidity:      %s%%\nWind:          %s km/h" \
    "$icon" "$condition_text" \
    "$temp_c" "$feels_like" "$humidity" "$wind_speed")

    local css_class="normal"
    if (( temp_c >= 40 )); then
        css_class="very-hot"
    elif (( temp_c >= 32 )); then
        css_class="hot"
    elif (( temp_c <= 5 )); then
        css_class="cold"
    fi

    local json_out
    json_out=$(jq -cn \
        --arg text "$text" \
        --arg tooltip "$tooltip" \
        --arg class "$css_class" \
        '{text: $text, tooltip: $tooltip, class: $class}')

    echo "$json_out" > "$CACHE_FILE"
    echo "$(date +%s)" >> "$CACHE_FILE"

    echo "$json_out"
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
else
    fetch_weather
fi