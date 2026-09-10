#!/usr/bin/env bash
set -euo pipefail

run_codex=false
if [[ ${1:-} == --codex ]]; then
  run_codex=true
elif [[ $# -gt 0 ]]; then
  echo "Usage: $0 [--codex]" >&2
  exit 2
fi

proxy="http://127.0.0.1:7890"
socket="$HOME/.local/state/tailscale/tailscaled.sock"
"$HOME/.local/bin/tailscale" --socket="$socket" status >/dev/null
"$HOME/.local/bin/mihomo-user-service" status
printf 'baidu_http='
curl --noproxy '' --proxy "$proxy" -fsS -o /dev/null -w '%{http_code}\n' --max-time 30 https://www.baidu.com
printf 'huggingface_http='
curl --noproxy '' --proxy "$proxy" -fsS -o /dev/null -w '%{http_code}\n' --max-time 45 https://huggingface.co
printf 'python_http='
HTTP_PROXY="$proxy" HTTPS_PROXY="$proxy" ALL_PROXY="$proxy" \
http_proxy="$proxy" https_proxy="$proxy" all_proxy="$proxy" \
python3 -c 'import urllib.request; print(urllib.request.urlopen("https://www.baidu.com", timeout=30).status)'

if $run_codex; then
  command -v codex >/dev/null || { echo "codex is not installed or not on PATH" >&2; exit 1; }
  HTTP_PROXY="$proxy" HTTPS_PROXY="$proxy" ALL_PROXY="$proxy" \
  http_proxy="$proxy" https_proxy="$proxy" all_proxy="$proxy" \
  codex exec --sandbox read-only --skip-git-repo-check 'Reply with exactly: RULE_SPLIT_OK'
fi
if ss -lnt 2>/dev/null | grep -q '0\.0\.0\.0:7890'; then
  echo "Unsafe listener detected on 0.0.0.0:7890" >&2
  exit 1
fi
