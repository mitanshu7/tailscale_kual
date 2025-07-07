# Tailscale for Kindle (KUAL)

This (very) simple repo allows you to connect your kindle remotely from anywhere using Tailscale VPN.

## Prerequisites:

1. Jailbroken Kindle. ([see](https://kindlemodding.gitbook.io/kindlemodding))
2. [KUAL](https://wiki.mobileread.com/wiki/KUAL) installed. ([see](https://kindlemodding.gitbook.io/kindlemodding/post-jailbreak/installing-kual-mrpi))
3. [USBNetworking](https://wiki.mobileread.com/wiki/Kindle_Hacks_Information#USB_networking_UN) hack installed and [enabled](https://wiki.mobileread.com/wiki/USBNetwork).
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

2. Get the latest tailscale binaries for the `arm` architecture from [here](https://pkgs.tailscale.com/stable/#static). Or see releases page for a version that worked for me.

3. Place the `tailscale` and `tailscaled` binaries in the `tailscale/bin/` folder of this (local) repository.

4. Fill the empty `auth.key` file, in the `tailscale/bin/` folder with your [Tailscale Auth Key](https://tailscale.com/kb/1085/auth-keys) to skip having to login using the link. You may choose not to do so.

5. Place the **tailscale** (not the `tailscale_kual`) folder into the `extensions` folder on your kindle.

6. In the KUAL menu, start `tailscaled` first, wait for about 10 seconds, then start `tailscale`.

7. Plug in the Kindle to PC. You can find the url to login in the `extensions/tailscale/` folder in `tailscale_start_log.txt` file, if this is a first time setup or you chose to not fill the auth key.

8. Copy the login url to a modern web browser and login using your preferred SSO. Skip to next step if you filled a valid auth key.

9. After connecting the device, tailscale should add the kindle to your [Machines](https://login.tailscale.com/admin/machines) page on tailscale [admin console](https://login.tailscale.com/welcome).

10. Now you can see the (fairly static) IP address assigned by Tailscale for your kindle. You can use this ip to connect!

11. In case you want to restart fresh (deleling the logs, and removing machine from tailscale etc.), you should first stop both `tailscale` and `tailscaled` respectively from KUAL menu, then connect kindle to PC for troubleshooting.

12. Note: Make sure the kindle screen is on, else the kindle sleeps the wifi. You can also not connect to kindle via ssh when it is connected to PC using the cable.

## Note:

Check out Open/Closed issues if this does not work right out of the gate.
