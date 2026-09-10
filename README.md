# Tailscale + Mihomo Setup

A Codex skill for deploying a rootless, user-space Tailscale client and a localhost-only Mihomo rule proxy on Linux servers.

It is designed for servers where administrative SSH traffic should travel over Tailscale—optionally through a self-hosted Peer Relay—while command-line applications use Mihomo for regional proxy routing.

## Architecture

```text
SSH administration
Client -> Tailscale -> optional Peer Relay -> target server

Target-server internet traffic
curl / Python / Codex
        -> 127.0.0.1:7890
        -> Mihomo rules
           |-- mainland China -> DIRECT
           `-- other traffic  -> subscription proxy
```

The Peer Relay is not configured as an HTTP proxy or exit node. Only applications that honor `HTTP_PROXY`, `HTTPS_PROXY`, or `ALL_PROXY` use Mihomo; this project does not install a transparent system-wide proxy.

## Features

- Rootless Tailscale in userspace-networking mode
- Custom Tailscale state and socket under `~/.local/state`
- Optional self-hosted Tailscale Peer Relay guidance
- Mihomo bound exclusively to `127.0.0.1:7890`
- Mainland-China DIRECT rules with a subscription-proxy fallback
- SHA-256 verification for pinned binaries
- `screen`-based process persistence when user systemd is unavailable
- Hidden subscription input and private configuration permissions
- Staged migration from legacy proxy port 7897
- Connectivity checks for curl, Python, and optionally Codex

## Requirements

- Linux on `x86_64`
- Bash, curl, gzip, tar, sha256sum, and `screen`
- A Tailscale account
- A Mihomo-compatible subscription
- Codex CLI for the optional Codex end-to-end test

The bundled installers currently pin:

- Tailscale `1.102.3`
- Mihomo `1.19.30`

Other architectures intentionally stop before downloading a binary. Add and verify architecture-specific assets and checksums before extending support.

## Install as a Codex skill

```bash
git clone https://github.com/givingupcoke/tailscale-mihomo-setup.git \
  ~/.codex/skills/tailscale-mihomo-setup
```

Start a new Codex session so the skill catalog is refreshed, then invoke it explicitly:

```text
Use $tailscale-mihomo-setup to deploy rootless Tailscale and Mihomo on this
server. Set the Tailscale hostname to fw4-example and use my existing Peer
Relay.
```

Codex will inspect the host before changing it, preserve existing configuration, and wait for required user-controlled inputs such as Tailscale authentication and the Mihomo subscription URL.

## Repository layout

```text
.
|-- SKILL.md
|-- agents/
|   `-- openai.yaml
|-- assets/
|   |-- mihomo-config.yaml.template
|   |-- mihomo-user-service
|   `-- tailscale-user-service
|-- references/
|   `-- peer-relay.md
`-- scripts/
    |-- configure_mihomo.sh
    |-- install_mihomo.sh
    |-- install_services.sh
    |-- install_tailscale.sh
    `-- verify.sh
```

`SKILL.md` is the Codex entry point. The scripts perform repeatable installation and verification, while assets are copied into the target user's home directory when needed.

## Security notes

- Never commit a real subscription URL, Tailscale auth key, state file, provider cache, or SSH credential.
- Installer downloads explicitly ignore inherited proxy variables.
- Mihomo must listen on `127.0.0.1:7890`, never `0.0.0.0:7890`.
- The shell proxy is changed only after domestic and foreign HTTPS tests pass through Mihomo.
- Tailnet policy, cloud firewall, and relay-server changes require explicit authorization.
- A third-party HTTPS download mirror is used only if direct GitHub access fails, and the downloaded Mihomo archive must match the pinned checksum.

## Process lifetime

The service wrappers use detached `screen` sessions. They survive an SSH disconnect but not a server reboot. Unless another authorized startup mechanism is configured, restart them after a reboot:

```bash
tailscale-user-service start
mihomo-user-service start
```

## Validation

Validate the skill metadata with Codex's `skill-creator` validator and check the shell scripts before publishing changes:

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py .
bash -n scripts/*.sh assets/*-user-service
```

For a configured target server:

```bash
scripts/verify.sh
scripts/verify.sh --codex
```

## License

This project is released under the [MIT License](LICENSE).
