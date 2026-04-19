#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "smoke-opencode: $1" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "${script_dir}/.." && pwd -P)"
prompt="${1:-Answer in one short sentence: READY from OmniRoute via OpenCode.}"
health_url="${OMNIROUTE_HEALTH_URL:-http://127.0.0.1:20128/api/monitoring/health}"

if ! curl --fail --silent --show-error --connect-timeout 5 --max-time 15 "${health_url}" >/dev/null; then
  fail "OmniRoute health check failed at ${health_url}"
fi

"${repo_root}/scripts/run-opencode.sh" run "${prompt}"
