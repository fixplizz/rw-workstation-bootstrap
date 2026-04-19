#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "unlock-secrets: $1" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "${script_dir}/.." && pwd -P)"
default_secrets_dir="$(cd "${repo_root}/.." && pwd -P)/rw-workstation-secrets"
secrets_dir="${RW_SECRETS_DIR:-${default_secrets_dir}}"
unlock_script="${secrets_dir}/scripts/vault-unlock.sh"
vault_file="${secrets_dir}/vault/workstation-secrets.tar.gz.enc"
omniroute_env="${secrets_dir}/env/omniroute/.env"

case "${1:-}" in
  "")
    ;;
  --check)
    [[ -f "${unlock_script}" ]] || fail "missing unlock script: ${unlock_script}"
    [[ -f "${vault_file}" ]] || fail "missing encrypted vault: ${vault_file}"
    echo "unlock-secrets: encrypted vault is available"
    exit 0
    ;;
  -h|--help)
    echo "Usage: $(basename "$0") [--check]" >&2
    exit 0
    ;;
  *)
    fail "unknown argument: ${1}"
    ;;
esac

if [[ -f "${omniroute_env}" && "${RW_VAULT_FORCE:-0}" != "1" ]]; then
  echo "unlock-secrets: OmniRoute env already exists; skipping vault unlock"
  exit 0
fi

[[ -x "${unlock_script}" ]] || fail "missing executable unlock script: ${unlock_script}"
[[ -f "${vault_file}" ]] || fail "missing encrypted vault: ${vault_file}"

"${unlock_script}"
