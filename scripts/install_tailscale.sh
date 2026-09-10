#!/usr/bin/env bash
set -euo pipefail

version="1.102.3"
tailscale_sha="d6ffcba02fa07728f0c4847fc06d61f239f763478bd59156abf3591bdb1a3ad1"
tailscaled_sha="ce4770bbe6fc9dbcf47d8a2ccc5efad73e3f975460b01738dd0b059879d01221"

[[ $(uname -m) == x86_64 ]] || { echo "Pinned installer supports x86_64 only." >&2; exit 2; }

cache_dir="$HOME/.cache/tailscale"
install_dir="$HOME/.local/lib/tailscale-$version"
archive="$cache_dir/tailscale_${version}_amd64.tgz"
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT
mkdir -p "$cache_dir" "$install_dir" "$HOME/.local/bin"

env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
  curl --noproxy '*' -fL --retry 3 -o "$archive" \
  "https://pkgs.tailscale.com/stable/tailscale_${version}_amd64.tgz"
tar -xzf "$archive" -C "$tmp_dir"
source_dir="$tmp_dir/tailscale_${version}_amd64"
printf '%s  %s\n' "$tailscale_sha" "$source_dir/tailscale" | sha256sum -c -
printf '%s  %s\n' "$tailscaled_sha" "$source_dir/tailscaled" | sha256sum -c -
install -m 755 "$source_dir/tailscale" "$install_dir/tailscale"
install -m 755 "$source_dir/tailscaled" "$install_dir/tailscaled"
ln -sfn "$install_dir/tailscale" "$HOME/.local/bin/tailscale"
ln -sfn "$install_dir/tailscaled" "$HOME/.local/bin/tailscaled"
"$HOME/.local/bin/tailscale" version
