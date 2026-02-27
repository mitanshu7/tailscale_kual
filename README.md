# Tailscale for Kindle (KUAL)

This (very) simple repo allows you to connect your kindle remotely from anywhere using Tailscale VPN.

## Prerequisites:

1. Jailbroken Kindle. ([see](https://kindlemodding.gitbook.io/kindlemodding))
2. [KUAL](https://wiki.mobileread.com/wiki/KUAL) installed. ([see](https://kindlemodding.gitbook.io/kindlemodding/post-jailbreak/installing-kual-mrpi))
3. [USBNetworking](https://www.mobileread.com/forums/showthread.php?t=225030) hack installed and [enabled](https://wiki.mobileread.com/wiki/USBNetwork).
4. Set up ssh keys for ease of use.

## My Kindle:

I have a PaperWhite (7th Generation), referred to as [PW3](https://wiki.mobileread.com/wiki/Kindle_Serial_Numbers).

```
[root@kindle root]# uname -a
Linux kindle 3.0.35-lab126 #8 PREEMPT Tue Aug 1 12:49:59 UTC 2023 armv7l GNU/Linux
```

Having tested out on this device only, [YMMV](https://dictionary.cambridge.org/dictionary/english/ymmv).

## Usage:

1. Download the repository.

2. Fill the empty `auth.key` file, in the `tailscale/bin/` folder with your [Tailscale Auth Key](https://tailscale.com/kb/1085/auth-keys) to login.

3. Place the **tailscale** (not the `tailscale_kual`) folder into the `extensions` folder on your kindle.

4. In the KUAL menu, tap **Install / Update Binaries**. This will download the latest `tailscale` and `tailscaled` ARM binaries directly onto the Kindle over Wi-Fi. Alternatively, download them manually for the `arm` architecture from [here](https://pkgs.tailscale.com/stable/#static) and place them in `extensions/tailscale/bin/` yourself.

5. In the KUAL menu, open the **Start Tailscaled** submenu and pick the mode that suits your device (see [Tailscaled Modes](#tailscaled-modes) below). Status messages will appear on the Kindle screen as the daemon starts. Wait a few seconds, then run **Start Tailscale**. You can switch modes at any time without manually stopping tailscaled first — the start scripts handle that automatically.

6. After this, tailscale should add the kindle to your [Machines](https://login.tailscale.com/admin/machines) page on tailscale [admin console](https://login.tailscale.com/welcome).

7. Now you can see the (fairly static) IP address assigned by Tailscale for your kindle. You can use this ip to `ssh root@<kindle-ip>`!

8. **Recommended:** In the [Tailscale admin console](https://login.tailscale.com/admin/machines), find your Kindle, click the three-dot menu, and select **Disable key expiry**. After this one-time step, the Kindle will reconnect to your tailnet on every reboot without needing the `auth.key` file again. The auth key is only needed for the very first registration.

9. In case you want to restart fresh, remove the Kindle from the Tailscale admin console, stop `tailscale` and `tailscaled` via KUAL, then delete the state and log files created in `/mnt/us/extensions/tailscale/bin/`: `tailscaled.state`, `tailscale_start_log.txt`, `tailscaled_start_log.txt`, `tailscaled_proxy_start_log.txt`, `tailscaled_tun_start_log.txt`, `tailscale_stop_log.txt`, `tailscaled_stop_log.txt`, `autostart_log.txt`, `status_log.txt`, and `update_log.txt`. This will fully reset Tailscale's registration on your Kindle.

10. Note: Make sure the kindle screen is on, else the kindle sleeps the wifi. You can also not connect to kindle via ssh when it is connected to PC using the cable.

## Tailscaled Modes

The **Start Tailscaled** entry in KUAL is now a submenu with three options. They each map to a different way of running `tailscaled`. Try them in this order if one does not work:

### 1. Standard (Userspace) — default

Runs `tailscaled` with `-tun userspace-networking`. This is what the extension has always done. The kindle joins your tailnet and is reachable by its Tailscale IP (good for SSH), but **outgoing connections from the kindle itself** (e.g. accessing other tailnet nodes) may not work on all devices or firmware versions.

### 2. Proxy Mode (SOCKS5/HTTP)

Runs `tailscaled` in userspace-networking mode but also starts a SOCKS5 and HTTP proxy listener on `localhost:1055`. Outgoing traffic from apps that respect a proxy setting is routed through Tailscale. This is the recommended option if you want to use Tailscale URLs inside **KOReader** (OPDS, the CWA plugin, etc.).

The proxy listen address defaults to `localhost:1055`. To use a different address or port, write it (e.g. `localhost:1080`) into the `proxy.address` file in `extensions/tailscale/bin/` before starting.

After starting tailscaled in this mode and bringing tailscale up, configure KOReader's network proxy:

- Open KOReader → **Settings** → **Network** → **Proxy Settings**
- Set type to **SOCKS5** (or HTTP)
- Host: `localhost`, Port: `1055` (or whatever you set in `proxy.address`)

Once set, any request KOReader makes will go out through your tailnet.

### 3. Kernel TUN (if supported)

Runs `tailscaled` without the userspace-networking flag, relying on the kernel's TUN/TAP module instead. This gives full system-wide outgoing connectivity but requires the `tun` kernel module to be present and loadable. **This is not available on all Kindle firmware versions** — if it fails silently, fall back to Proxy Mode.

## Installing and Updating Tailscale Binaries

The KUAL menu has a single **Install / Update Binaries** entry that handles both cases automatically:

- **Fresh install** (no binaries present): fetches the latest release from the GitHub API, downloads `tailscale_{version}_arm.tgz` from `pkgs.tailscale.com`, installs `tailscale` and `tailscaled` into `extensions/tailscale/bin/`, and creates an empty `auth.key` placeholder if one is not already there.
- **Already installed**: reads the current version, skips the download if already up to date, otherwise backs up the existing binaries as `*.bak` and installs the newer version.

Status messages are shown on-screen as the script runs. Full progress and any errors are also written to `update_log.txt` in `extensions/tailscale/bin/`. The Kindle must have an active Wi-Fi connection.

**Tip:** All KUAL actions (start, stop, update) display live status on the Kindle screen and write a corresponding log file in `extensions/tailscale/bin/` — check those logs first when troubleshooting.

**Note:** If the daemon is already running during an upgrade, the script will automatically stop it, install the new binaries, and restart it in the same mode — no manual intervention needed.

## Autostart on Boot

Tailscale can be configured to start automatically when the Kindle boots, using the Kindle's native upstart init system. The first time you enable autostart, the extension installs a small upstart job to `/etc/upstart/` (this requires a one-time rootfs write via `mntroot`). After that, autostart is toggled by a simple trigger file — no further system changes needed.

### Enabling

In the KUAL menu, open **Autostart** → **Enable Autostart**. This will:

1. Install the upstart job `/etc/upstart/tailscale-autostart.conf` if not already present.
2. Create a trigger file (`autostart.enabled`) in the extension's `bin/` directory.

On every subsequent boot, the upstart job checks for the trigger file and, if present, runs the autostart script which will:

1. Wait up to 2 minutes for Wi-Fi to become available.
2. Start `tailscaled` in the configured mode.
3. Connect to your tailnet (reconnect first, auth key fallback).

### Disabling

Open **Autostart** → **Disable Autostart** to remove the trigger file. The upstart job stays installed but does nothing without the trigger. This does not stop a currently running Tailscale session.

### Choosing the Mode

In the KUAL menu, open **Autostart** → **Set Mode** and pick one of:

- **Standard (Userspace)** — default
- **Proxy Mode (SOCKS5/HTTP)** — uses the address from `proxy.address`
- **Kernel TUN**

The selected mode is stored in `extensions/tailscale/bin/autostart.mode`. You can also edit this file directly if you prefer.

### Logs

Autostart progress and errors are written to `extensions/tailscale/bin/autostart_log.txt`.

## Status

Tap **Status** at the top of the Tailscale KUAL menu to display a summary on the Kindle screen:

- **tailscaled**: running or stopped
- **tailscale**: connected, disconnected, or other backend state
- **IP**: your Tailscale IP address (if connected)
- **Autostart mode**: standard, proxy, or tun
- **Autostart**: enabled or disabled

Output is also written to `extensions/tailscale/bin/status_log.txt`.

## Note:

Check out Open/Closed issues if this does not work right out of the gate.
