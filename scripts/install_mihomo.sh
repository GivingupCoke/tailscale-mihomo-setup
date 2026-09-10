#!/usr/bin/env bash
set -euo pipefail

version="1.19.30"
archive_sha="cf06ce2c7d1421bdbda14ee4a5b6046672dc35ebf8eecd8e77504ec3c0ed9a84"
[[ $(uname -m) == x86_64 ]] || { echo "Pinned installer supports x86_64 only." >&2; exit 2; }

cache_dir="$HOME/.cache/mihomo"
archive="$cache_dir/mihomo-linux-amd64-v${version}.gz"
asset="https://github.com/MetaCubeX/mihomo/releases/download/v${version}/mihomo-linux-amd64-v${version}.gz"
mirror="https://gh-proxy.com/$asset"
mkdir -p "$cache_dir" "$HOME/.local/bin"

download() {
  env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
    curl --noproxy '*' -fL --retry 2 --connect-timeout 15 --max-time 180 -o "$archive" "$1"
}
if ! download "$asset"; then
  echo "Direct GitHub failed; using the checksum-verified HTTPS mirror." >&2
  download "$mirror"
fi
printf '%s  %s\n' "$archive_sha" "$archive" | sha256sum -c -
gzip -dc "$archive" > "$HOME/.local/bin/mihomo"
chmod 755 "$HOME/.local/bin/mihomo"
"$HOME/.local/bin/mihomo" -v
