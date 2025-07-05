#!/bin/sh
nohup /mnt/us/extensions/tailscale/bin/tailscaled --statedir=/mnt/us/extensions/tailscale/bin/ -tun userspace-networking > tailscaled_start_log.txt 2>&1 &
