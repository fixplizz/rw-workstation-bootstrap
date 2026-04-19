#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "test-omniroute-sandbox: $1" >&2
  exit 1
}

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    fail "required command not found: ${command_name}"
  fi
}

generate_key() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return
  fi

  LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | head -c 64
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "${script_dir}/.." && pwd -P)"
omniroute_dir="${repo_root}/bootstrap/omniroute"
runtime_dir="${repo_root}/.runtime/omniroute-sandbox"
sandbox_env="${runtime_dir}/.env"
sandbox_port="${RW_OMNIROUTE_SANDBOX_PORT:-20129}"
sandbox_project="${RW_OMNIROUTE_SANDBOX_PROJECT:-rw-omniroute-bootstrap-sandbox}"
sandbox_container="${RW_OMNIROUTE_SANDBOX_CONTAINER:-rw-omniroute-bootstrap-sandbox}"
sandbox_volume="${RW_OMNIROUTE_SANDBOX_VOLUME:-rw-omniroute-bootstrap-sandbox-data}"
health_path="${RW_OMNIROUTE_SANDBOX_HEALTH_PATH:-/api/monitoring/health}"

require_command docker
require_command curl

if ! docker compose version >/dev/null 2>&1; then
  fail "docker compose is unavailable"
fi

mkdir -p "${runtime_dir}"
chmod 700 "${runtime_dir}"

if [[ ! -f "${sandbox_env}" ]]; then
  cat >"${sandbox_env}" <<EOF
OMNIROUTE_IMAGE=diegosouzapw/omniroute:latest
HOST_PORT=${sandbox_port}
PORT=20128
NEXT_PUBLIC_BASE_URL=http://localhost:${sandbox_port}
DATA_DIR=/app/data
STORAGE_ENCRYPTION_KEY=$(generate_key)
DISABLE_SQLITE_AUTO_BACKUP=true
INITIAL_PASSWORD=CHANGEME-SANDBOX
OMNIROUTE_HEALTHCHECK_URL=${health_path}
EOF
  chmod 600 "${sandbox_env}"
fi

if docker ps --format '{{.Names}}' | grep -Fxq "${sandbox_container}"; then
  echo "test-omniroute-sandbox: reusing running sandbox container ${sandbox_container}"
fi

cd "${omniroute_dir}"

OMNIROUTE_ENV_FILE="${sandbox_env}" \
OMNIROUTE_CONTAINER_NAME="${sandbox_container}" \
OMNIROUTE_VOLUME_NAME="${sandbox_volume}" \
docker compose \
  --project-name "${sandbox_project}" \
  --env-file "${sandbox_env}" \
  up -d --force-recreate

health_url="http://127.0.0.1:${sandbox_port}${health_path}"

for _ in {1..30}; do
  if curl --fail --silent --show-error --connect-timeout 3 --max-time 10 "${health_url}" >/dev/null; then
    echo "test-omniroute-sandbox: health check passed at ${health_url}"
    echo "test-omniroute-sandbox: container=${sandbox_container}"
    echo "test-omniroute-sandbox: volume=${sandbox_volume}"
    exit 0
  fi
  sleep 2
done

fail "sandbox health check did not pass at ${health_url}"
