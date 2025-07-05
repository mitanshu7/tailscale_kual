#!/bin/sh
nohup /mnt/us/extensions/tailscale/bin/tailscale down > tailscale_stop_log.txt 2>&1 &
