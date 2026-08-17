#!/bin/sh

BIN=/mnt/us/extensions/tailscale/bin

pause() {
    printf '\nPress Enter to return to the menu... '
    read -r ignored
}

run() {
    TAILSCALE_SCRIPTLET=1 "$BIN/$1"
    pause
}

while true; do
    clear
    echo "Tailscale for Kindle"
    echo "===================="
    echo "1) Start tailscaled (userspace)"
    echo "2) Start tailscaled (proxy)"
    echo "3) Start tailscaled (kernel TUN)"
    echo "4) Start Tailscale"
    echo "5) Stop Tailscale"
    echo "6) Stop tailscaled"
    echo "7) Install / update binaries"
    echo "8) Exit"
    echo
    printf 'Choose an option: '
    read -r choice

    case "$choice" in
        1) run start_tailscaled.sh ;;
        2) run start_tailscaled_proxy.sh ;;
        3) run start_tailscaled_tun.sh ;;
        4) run start_tailscale.sh ;;
        5) run stop_tailscale.sh ;;
        6) run stop_tailscaled.sh ;;
        7) run update_tailscale.sh ;;
        8) exit 0 ;;
        *) echo "Unknown option."; pause ;;
    esac
done
