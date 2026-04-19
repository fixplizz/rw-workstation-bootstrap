#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "setup-workstation: $1" >&2
  exit 1
}

need_cmd() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    fail "required command not found: ${command_name}"
  fi
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

resolve_repo_root() {
  local root_dir

  root_dir="$(cd "${script_dir}/.." && pwd -P)"
  if [[ ! -d "${root_dir}" ]]; then
    fail "unable to resolve repository root"
  fi

  printf '%s\n' "${root_dir}"
}

check_compose_available() {
  if ! docker compose version >/dev/null 2>&1; then
    fail "docker compose is unavailable"
  fi
}

require_setup_scripts() {
  local required_scripts=(
    "${repo_root}/scripts/link-secrets.sh"
    "${repo_root}/scripts/install-opencode.sh"
    "${repo_root}/scripts/install-codex-assets.sh"
    "${repo_root}/scripts/run-opencode.sh"
    "${repo_root}/scripts/install-omniroute.sh"
    "${repo_root}/scripts/verify-workstation.sh"
  )
  local script_path
  local missing=()
  local non_executable=()

  for script_path in "${required_scripts[@]}"; do
    if [[ ! -e "${script_path}" ]]; then
      missing+=("$(basename "${script_path}")")
    elif [[ ! -x "${script_path}" ]]; then
      non_executable+=("$(basename "${script_path}")")
    fi
  done

  if (( ${#missing[@]} > 0 || ${#non_executable[@]} > 0 )); then
    if (( ${#missing[@]} > 0 )); then
      fail "required script(s) missing: ${missing[*]}"
    fi

    fail "required script(s) not executable: ${non_executable[*]}"
  fi
}

check_preflight_dependencies() {
  local repo_root

  repo_root="$(resolve_repo_root)"
  require_setup_scripts

  need_cmd bash
  need_cmd git
  need_cmd docker
  need_cmd curl
  check_compose_available

  if [[ ! -x "${repo_root}/scripts/link-secrets.sh" ]]; then
    fail "repo root is missing expected executable scripts/link-secrets.sh"
  fi
}

ensure_setup_steps_implemented() {
  local downstream_stub=()
  local step_script

  for step_script in \
    "${repo_root}/scripts/install-opencode.sh" \
    "${repo_root}/scripts/install-codex-assets.sh"
  do
    if grep -Fq 'RW_WORKSTATION_STEP_IMPLEMENTATION="stub"' "${step_script}"; then
      downstream_stub+=("$(basename "${step_script}")")
    fi
  done

  if (( ${#downstream_stub[@]} > 0 )); then
    fail "refusing to start setup while these steps are still stubs: ${downstream_stub[*]}"
  fi
}

case "${1:-}" in
  --check)
    if [[ $# -ne 1 ]]; then
      echo "Usage: $(basename "$0") [--check]" >&2
      exit 2
    fi

    check_preflight_dependencies

    echo "Preflight OK"
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Usage: $(basename "$0") [--check]" >&2
    exit 2
    ;;
esac

need_cmd bash
need_cmd git
need_cmd docker
need_cmd curl

repo_root="$(resolve_repo_root)"
require_setup_scripts
check_compose_available
ensure_setup_steps_implemented

"${repo_root}/scripts/link-secrets.sh"
"${repo_root}/scripts/install-opencode.sh"
"${repo_root}/scripts/install-codex-assets.sh"
"${repo_root}/scripts/install-omniroute.sh"
"${repo_root}/scripts/verify-workstation.sh" --slice omniroute
