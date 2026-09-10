---
name: tailscale-mihomo-setup
description: Deploy, verify, or repair rootless user-space Tailscale and a localhost-only Mihomo rule proxy on Linux servers, including optional use of an existing Tailscale Peer Relay. Use for repeating the school-server setup where SSH travels over Tailscale while proxy-aware applications use Mihomo; do not use for system-wide transparent proxying or unrelated VPN configurations.
---

# Tailscale and Mihomo Setup

Build two separate traffic paths:

- SSH management: client -> Tailscale -> optional Peer Relay -> target server.
- Target internet access: proxy-aware application -> `127.0.0.1:7890` -> Mihomo -> DIRECT or subscription proxy.

The Peer Relay must not become an HTTP proxy or exit node. This does not configure transparent routing; programs that ignore proxy environment variables remain outside Mihomo.

## Safety invariants

- Inspect architecture, `$HOME`, `screen`, user systemd, current listeners, proxy variables, shell startup files, Codex policy, and Tailscale state before changing anything.
- Preserve existing configuration and avoid modifying unrelated lines. Back up a configuration file before replacing it.
- Never embed subscription URLs, auth keys, node credentials, or login URLs in the skill, logs, or final response. Redact them from output.
- Download installers with all proxy variables removed. Never use an old SSH reverse proxy such as port 7897 for installer traffic.
- Do not switch shell proxy variables to 7890 until Mihomo listens on localhost and domestic and foreign HTTPS tests both pass through it.
- Bind Mihomo only to `127.0.0.1`; reject `0.0.0.0:7890`.
- Do not edit tailnet policy, cloud firewall, or relay hosts unless the user placed them in scope.

## Workflow

1. Determine whether this is an install, repair, or verification run. Preserve a working component rather than reinstalling it.
2. For a rootless x86_64 install, run `scripts/install_tailscale.sh`, then `scripts/install_services.sh`. Start Tailscale with `tailscale-user-service start`.
3. Ask for a unique hostname if none was supplied, then authenticate through the custom socket:

   ```bash
   ~/.local/bin/tailscale --socket="$HOME/.local/state/tailscale/tailscaled.sock" up --hostname="HOSTNAME" --accept-dns=false
   ```

   Browser authentication or an auth key is a user-controlled step. Do not enable an exit node or Tailscale SSH unless explicitly requested.
4. For Peer Relay work, read `references/peer-relay.md`. Verify relay use only after generating actual client-to-server traffic.
5. Run `scripts/install_mihomo.sh`, then `scripts/configure_mihomo.sh`. Prefer the hidden interactive subscription prompt. Supply a node-name regex only when the desired node is known; otherwise leave it empty and inspect nodes before choosing.
6. Keep `config.yaml` and the provider cache at mode 600. Run `mihomo-user-service test`, `start`, and `status`.
7. Test domestic and foreign URLs explicitly through `http://127.0.0.1:7890`. If either fails, diagnose providers, filter, DNS, geodata, and logs while leaving the old shell proxy untouched.
8. Once healthy, place this block before `.bashrc`'s non-interactive early return:

   ```bash
   export HTTP_PROXY=http://127.0.0.1:7890
   export HTTPS_PROXY=http://127.0.0.1:7890
   export ALL_PROXY=http://127.0.0.1:7890
   export http_proxy="$HTTP_PROXY"
   export https_proxy="$HTTPS_PROXY"
   export all_proxy="$ALL_PROXY"
   export NO_PROXY=127.0.0.1,localhost,::1,.ts.net
   export no_proxy="$NO_PROXY"
   ```

   Remove old 7897 exports. A remaining 7897 listener can belong to the BIMSA-side `RemoteForward`; explain that it is unused after references are removed and closes only after removing that client setting and reconnecting.
9. Inspect `~/.codex/config.toml`. Remove only filters excluding `HTTP_PROXY`, `HTTPS_PROXY`, or `ALL_PROXY`. Ordinary `codex` should replace a legacy `codex-proxy` wrapper.
10. Run `scripts/verify.sh`; add `--codex` for an end-to-end Codex check. If proof of rule selection is needed, temporarily use Mihomo info logging, capture DIRECT/PROXY evidence, then restore `warning`.

## Handoff

Report versions, listener, test results, Peer Relay evidence, files changed, and external actions remaining. Explain that `screen` survives SSH disconnects but not a reboot; after reboot both service wrappers need `start` unless the user separately requests a startup mechanism.
