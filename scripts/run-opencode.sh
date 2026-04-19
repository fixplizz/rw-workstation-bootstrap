#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "run-opencode: $1" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "${script_dir}/.." && pwd -P)"
default_secrets_dir="$(cd "${repo_root}/.." && pwd -P)/rw-workstation-secrets"
secrets_dir="${RW_SECRETS_DIR:-${default_secrets_dir}}"

load_env_file() {
  local env_file="$1"

  if [[ -f "${env_file}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${env_file}"
    set +a
  fi
}

if ! command -v opencode >/dev/null 2>&1; then
  if [[ -x "${HOME}/.opencode/bin/opencode" ]]; then
    export PATH="${HOME}/.opencode/bin:${PATH}"
  else
    fail "opencode is not installed or not on PATH; run scripts/setup-workstation.sh first"
  fi
fi

load_env_file "${secrets_dir}/env/providers/nvidia.env"
load_env_file "${secrets_dir}/env/providers/nvidia.env.local"
load_env_file "${secrets_dir}/env/providers/openrouter.env"
load_env_file "${secrets_dir}/env/providers/openrouter.env.local"
load_env_file "${secrets_dir}/env/providers/other.env"
load_env_file "${secrets_dir}/env/providers/other.env.local"

if [[ -z "${OMNIROUTE_API_KEY:-}" ]]; then
  echo "run-opencode: OMNIROUTE_API_KEY is not set in provider env files; OpenCode may prompt/fail until you add it to the private secrets repo" >&2
fi

exec opencode "$@"
