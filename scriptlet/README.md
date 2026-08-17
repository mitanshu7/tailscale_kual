# Tailscale scriptlet launcher

This payload runs without KUAL. It uses SH_Integration to expose
`documents/Tailscale.sh` in the Kindle Library and the bundled kterm 2.6
terminal to present a small interactive menu.

From the repository root, run `./build-scriptlet.sh`. Copy the contents of
the generated ZIP to the Kindle USB root. Fill in
`extensions/tailscale/bin/auth.key`, or use an existing Tailscale state file,
then open **Tailscale** from the Library.

This requires a jailbroken Kindle with the Universal Hotfix/SH_Integration.
The bundled kterm release is the legacy ARM build. Newer ARMHF devices may
need a matching kterm build before this package can be used on-device.
