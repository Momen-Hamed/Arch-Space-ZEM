#!/bin/bash
uptime_info="Uptime: $(uptime -p | sed 's/up //')"
os_age="OS age: $(( ($(date +%s) - $(stat -c %W /)) / 86400 )) days"

jq -cn \
--arg tooltip "$(printf '%s\n%s' "$uptime_info" "$os_age")" \
'{tooltip: $tooltip}'
