#!/bin/sh
/mnt/us/extensions/tailscale/bin/tailscaled -cleanup > tailscaled_stop_log.txt 2>&1
kh_msg "$(cat tailscaled_stop_log.txt)"
