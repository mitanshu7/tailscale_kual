#!/bin/sh
nohup /mnt/us/extensions/tailscale/bin/tailscale up --auth-key=$(cat /mnt/us/extensions/tailscale/bin/auth.key)> tailscale_start_log.txt 2>&1 &

