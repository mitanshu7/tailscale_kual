#!/bin/sh
/mnt/us/extensions/tailscale/bin/tailscale up > tailscale_start_log.txt 2>&1
kh_msg "$(cat tailscale_start_log.txt)"

