#!/bin/sh
nohup /mnt/us/extensions/tailscale/bin/tailscaled -cleanup > tailscaled_stop_log.txt 2>&1 &
