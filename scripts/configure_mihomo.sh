#!/usr/bin/env bash
set -euo pipefail
umask 077

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
template="$script_dir/../assets/mihomo-config.yaml.template"
config_dir="$HOME/.config/mihomo"
config_file="$config_dir/config.yaml"
subscription_url=${MIHOMO_SUBSCRIPTION_URL:-}
node_filter=${MIHOMO_NODE_FILTER:-}

if [[ -z "$subscription_url" ]]; then
  [[ -t 0 ]] || { echo "Run interactively or provide MIHOMO_SUBSCRIPTION_URL without logging it." >&2; exit 2; }
  read -r -s -p "Mihomo subscription URL: " subscription_url
  printf '\n'
fi
if [[ ! "$subscription_url" =~ ^https?:// ]] || [[ "$subscription_url" == *$'\n'* ]]; then
  echo "Subscription URL must be a single HTTP(S) URL." >&2
  exit 2
fi
if [[ -z "$node_filter" && -t 0 ]]; then
  read -r -p "Optional node-name regex filter (empty means all nodes): " node_filter
fi

escaped_url=${subscription_url//\\/\\\\}
escaped_url=${escaped_url//\"/\\\"}
if [[ -n "$node_filter" ]]; then
  escaped_filter=${node_filter//\'/\'\'}
  filter_line="    filter: '$escaped_filter'"
else
  filter_line=""
fi

mkdir -p "$config_dir/providers" "$HOME/.local/state/mihomo"
chmod 700 "$config_dir" "$config_dir/providers" "$HOME/.local/state/mihomo"
if [[ -e "$config_file" ]]; then
  backup="$config_file.backup.$(date +%Y%m%d-%H%M%S)"
  cp -p -- "$config_file" "$backup"
  echo "Backed up existing config to $backup"
fi

tmp_file=$(mktemp "$config_dir/config.yaml.tmp.XXXXXX")
while IFS= read -r line || [[ -n "$line" ]]; do
  line=${line//__SUBSCRIPTION_URL__/$escaped_url}
  line=${line//__FILTER_LINE__/$filter_line}
  printf '%s\n' "$line"
done < "$template" > "$tmp_file"
chmod 600 "$tmp_file"
mv -f -- "$tmp_file" "$config_file"
echo "Wrote $config_file with private permissions."
