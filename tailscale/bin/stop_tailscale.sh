#!/bin/sh
/mnt/us/extensions/tailscale/bin/tailscale down > tailscale_stop_log.txt 2>&1
kh_msg "$(cat tailscale_stop_log.txt)"
