#!/bin/sh
/mnt/us/extensions/tailscale/bin/tailscaled -tun userspace-networking -no-logs-no-support > tailscaled_start_log.txt 2>&1
kh_msg "$(cat tailscaled_start_log.txt)"
