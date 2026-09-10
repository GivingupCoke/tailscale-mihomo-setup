#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
asset_dir="$script_dir/../assets"
mkdir -p "$HOME/.local/bin" "$HOME/.local/state/tailscale" "$HOME/.local/state/mihomo"
chmod 700 "$HOME/.local/state/tailscale" "$HOME/.local/state/mihomo"
install -m 755 "$asset_dir/tailscale-user-service" "$HOME/.local/bin/tailscale-user-service"
install -m 755 "$asset_dir/mihomo-user-service" "$HOME/.local/bin/mihomo-user-service"
echo "Installed user service wrappers in $HOME/.local/bin"
