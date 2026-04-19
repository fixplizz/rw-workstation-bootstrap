#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "install-omniroute: $1" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "${script_dir}/.." && pwd -P)"
bootstrap_dir="${repo_root}/bootstrap/omniroute"
env_file="${bootstrap_dir}/.env.local"

"${repo_root}/scripts/link-secrets.sh"

if [[ ! -f "${env_file}" ]]; then
  fail "expected ${env_file} after linking secrets"
fi

cd "${bootstrap_dir}"

docker compose --env-file "${env_file}" up -d --force-recreate
