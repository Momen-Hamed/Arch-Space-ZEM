#!/usr/bin/env bash
# Root GUI Apps Reload Script

# Relaunch with sudo if not root
if [[ $EUID -ne 0 ]]; then
    sudo -E "$0" "$@"
    exit
fi

echo "🔐 Reloading running root GUI apps..."

restart_root_app() {
    local process="$1"

    if pgrep -f "$process" >/dev/null; then
        echo "↻ Restarting $process"
        pkill -f "$process"
        sleep 1
        sudo -E "$process" &>/dev/null &
    else
        echo "• $process is not running, skipping"
    fi
}

restart_root_app gparted
restart_root_app timeshift-gtk

echo "✅ Done"