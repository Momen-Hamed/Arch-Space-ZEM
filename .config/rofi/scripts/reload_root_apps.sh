#!/usr/bin/env bash
# Root Apps Reload Script

# Export display env vars so root apps can connect to the session
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

restart_root_app() {
    local process="$1"
    local binary="${2:-$1}"

    if pgrep -x "$process" >/dev/null 2>&1; then
        sudo pkill -x "$process"
        sleep 0.5
        sudo -E "$binary" &>/dev/null &
    else
        echo "Process '$process' not found, skipping."
    fi
}

restart_root_app gpartedbin gparted
restart_root_app timeshift-gtk timeshift-gtk

wait
