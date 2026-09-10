# Tailscale Peer Relay

Read this reference only when configuring or diagnosing the existing cloud relay path.

## Relay server

Peer Relay requires Tailscale 1.86 or newer and an accessible UDP port. On an authorized relay host:

```bash
sudo tailscale set --relay-server-port=40000
```

Allow inbound UDP 40000 in the cloud security group and host firewall. Do not configure this machine as an exit node for this workflow.

## Tailnet policy

Merge, rather than overwrite, a narrow grant. `src` identifies stable devices behind restrictive networking; `dst` identifies the relay:

```json
{
  "grants": [
    {
      "src": ["TARGET-HOSTNAME-OR-TAG"],
      "dst": ["RELAY-HOSTNAME-OR-TAG"],
      "app": {
        "tailscale.com/cap/relay": []
      }
    }
  ]
}
```

The relay capability does not grant network access to the target. Ensure a separate ACL or grant lets the intended client reach target TCP port 22. Avoid `*` as `src`; prefer exact hostnames or tags.

## Verification

Generate actual SSH traffic, then inspect `tailscale status` through the target's custom socket. Successful use appears as:

```text
active; peer-relay PUBLIC-IP:40000:vni:..., tx ..., rx ...
```

Tailscale tries direct connectivity first, then available Peer Relays, then DERP. No `peer-relay` line while idle is not a failure.

Official documentation: https://tailscale.com/docs/features/peer-relay
