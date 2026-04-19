#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "${script_dir}/.." && pwd -P)"
omniroute_dir="${repo_root}/bootstrap/omniroute"
omniroute_env="${omniroute_dir}/.env.local"

fail() {
  echo "verify-workstation: $1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  verify-workstation.sh [--current]
  verify-workstation.sh --scaffold-only
  verify-workstation.sh --slice omniroute

The verifier currently covers the scaffold layout and the OmniRoute slice only.
Use --scaffold-only for repository layout checks, --slice omniroute for the
live OmniRoute container and health check, or --current to run both in order.
Bare invocation is treated as --current for convenience.

The script does not claim full workstation readiness yet.
EOF
}

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    fail "required command not found: ${command_name}"
  fi
}

parse_env_value() {
  local env_file="$1"
  local key="$2"

  awk -v key="${key}" '
    function ltrim(value) {
      sub(/^[[:space:]]+/, "", value)
      return value
    }

    function rtrim(value) {
      sub(/[[:space:]]+$/, "", value)
      return value
    }

    {
      line = $0
      sub(/\r$/, "", line)
      line = ltrim(line)

      if (line == "" || substr(line, 1, 1) == "#") {
        next
      }

      if (substr(line, 1, 7) == "export ") {
        line = substr(line, 8)
      }

      separator = index(line, "=")
      if (separator == 0) {
        next
      }

      name = rtrim(substr(line, 1, separator - 1))
      if (name != key) {
        next
      }

      value = ltrim(substr(line, separator + 1))
      value = rtrim(value)

      if ((value ~ /^".*"$/) || (value ~ /^'\''.*'\''$/)) {
        value = substr(value, 2, length(value) - 2)
      }

      print value
      found = 1
      exit
    }

    END {
      if (!found) {
        exit 1
      }
    }
  ' "${env_file}"
}

resolve_healthcheck_url() {
  local host_port="$1"
  local health_target="${2:-/api/monitoring/health}"

  if [[ -n "${health_target}" && "${health_target}" =~ ^[[:alpha:]][[:alnum:]+.-]*:// ]]; then
    fail "OMNIROUTE_HEALTHCHECK_URL must be a path-like override, not an absolute URL"
  fi

  if [[ "${health_target}" != /* ]]; then
    health_target="/${health_target}"
  fi

  printf 'http://127.0.0.1:%s%s\n' "${host_port}" "${health_target}"
}

verify_omniroute_running() {
  local running_services
  local container_running
  local container_name="rw-omniroute"

  if [[ -n "${OMNIROUTE_CONTAINER_NAME:-}" ]]; then
    container_name="${OMNIROUTE_CONTAINER_NAME}"
  elif container_name_from_env="$(parse_env_value "${omniroute_env}" "OMNIROUTE_CONTAINER_NAME" 2>/dev/null)"; then
    if [[ -n "${container_name_from_env}" ]]; then
      container_name="${container_name_from_env}"
    fi
  fi

  if ! running_services="$(
    cd "${omniroute_dir}" &&
      docker compose --env-file "${omniroute_env}" ps --status running --services
  )"; then
    fail "unable to inspect OmniRoute compose service state"
  fi

  if ! grep -Fxq "omniroute" <<<"${running_services}"; then
    fail "OmniRoute compose service is not running"
  fi

  if ! container_running="$(docker inspect --format '{{.State.Running}}' "${container_name}" 2>/dev/null)"; then
    fail "${container_name} container was not found"
  fi

  if [[ "${container_running}" != "true" ]]; then
    fail "${container_name} container is not running"
  fi
}

verify_omniroute_health() {
  local host_port
  local health_override
  local healthcheck_url

  if [[ ! -f "${omniroute_env}" ]]; then
    fail "required OmniRoute env link is missing: ${omniroute_env}"
  fi

  if ! host_port="$(parse_env_value "${omniroute_env}" "HOST_PORT")"; then
    fail "HOST_PORT is not set in ${omniroute_env}"
  fi

  if [[ -z "${host_port}" ]]; then
    fail "HOST_PORT is empty in ${omniroute_env}"
  fi

  health_override="$(parse_env_value "${omniroute_env}" "OMNIROUTE_HEALTHCHECK_URL" 2>/dev/null || true)"
  healthcheck_url="$(resolve_healthcheck_url "${host_port}" "${health_override:-/api/monitoring/health}")"

  if ! curl --fail --silent --show-error --connect-timeout 5 --max-time 15 "${healthcheck_url}" >/dev/null; then
    fail "OmniRoute HTTP check failed at ${healthcheck_url}"
  fi

  echo "verify-workstation: OmniRoute HTTP check passed at ${healthcheck_url}"
}

verify_omniroute_slice() {
  require_command docker
  require_command curl

  if ! docker compose version >/dev/null 2>&1; then
    fail "docker compose is unavailable"
  fi

  "${repo_root}/scripts/link-secrets.sh" --check
  if [[ ! -f "${omniroute_env}" ]]; then
    fail "required OmniRoute env link is missing: ${omniroute_env}"
  fi

  verify_omniroute_running
  verify_omniroute_health

  echo "verify-workstation: OmniRoute slice verification passed"
}

verify_scaffold_only() {
  local required_paths=(
    "README.md"
    ".gitignore"
    "scripts/setup-workstation.sh"
    "scripts/link-secrets.sh"
    "scripts/install-omniroute.sh"
    "scripts/install-opencode.sh"
    "scripts/install-codex-assets.sh"
    "scripts/run-opencode.sh"
    "scripts/test-omniroute-sandbox.sh"
    "scripts/verify-workstation.sh"
    "bootstrap/.gitkeep"
    "bootstrap/wsl/.gitkeep"
    "bootstrap/windows/.gitkeep"
    "bootstrap/omniroute/.gitkeep"
    "bootstrap/omniroute/compose.yaml"
    "bootstrap/omniroute/README.md"
    "bootstrap/opencode/.gitkeep"
    "bootstrap/codex/.gitkeep"
    "bootstrap/mcp/.gitkeep"
    "templates/omniroute/.gitkeep"
    "templates/opencode/.gitkeep"
    "templates/codex/.gitkeep"
    "templates/mcp/.gitkeep"
    "rules/README.md"
    "skills/README.md"
    "agents/README.md"
    "docs/README.md"
  )
  local executable_scripts=(
    "scripts/setup-workstation.sh"
    "scripts/link-secrets.sh"
    "scripts/install-omniroute.sh"
    "scripts/install-opencode.sh"
    "scripts/install-codex-assets.sh"
    "scripts/run-opencode.sh"
    "scripts/test-omniroute-sandbox.sh"
    "scripts/verify-workstation.sh"
  )
  local missing=()
  local non_executable=()
  local relative_path

  for relative_path in "${required_paths[@]}"; do
    if [[ ! -e "${repo_root}/${relative_path}" ]]; then
      missing+=("${relative_path}")
    fi
  done

  for relative_path in "${executable_scripts[@]}"; do
    if [[ ! -x "${repo_root}/${relative_path}" ]]; then
      non_executable+=("${relative_path}")
    fi
  done

  if (( ${#missing[@]} > 0 || ${#non_executable[@]} > 0 )); then
    echo "verify-workstation: scaffold verification failed" >&2
    if (( ${#missing[@]} > 0 )); then
      printf 'missing: %s\n' "${missing[@]}" >&2
    fi
    if (( ${#non_executable[@]} > 0 )); then
      printf 'not executable: %s\n' "${non_executable[@]}" >&2
    fi
    exit 1
  fi

  echo "verify-workstation: scaffold verification passed"
}

verify_current_scope() {
  verify_scaffold_only
  verify_omniroute_slice

  echo "verify-workstation: current implemented scope verification passed"
}

case "${1:-}" in
  "")
    verify_current_scope
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  --current)
    if [[ $# -ne 1 ]]; then
      usage >&2
      exit 2
    fi
    verify_current_scope
    ;;
  --scaffold-only)
    if [[ $# -ne 1 ]]; then
      usage >&2
      exit 2
    fi
    verify_scaffold_only
    ;;
  --slice)
    if [[ $# -ne 2 || "${2:-}" != "omniroute" ]]; then
      usage >&2
      exit 2
    fi
    verify_omniroute_slice
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
