#!/usr/bin/env bash
set -euo pipefail

readonly RW_WORKSTATION_STEP_IMPLEMENTATION="real"

fail() {
  echo "install-codex-assets: $1" >&2
  exit 1
}

usage() {
  echo "Usage: $(basename "$0") [--check]" >&2
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
templates_root="${repo_root}/templates"
force="${RW_CODEX_ASSETS_FORCE:-0}"

if [[ "${force}" != "0" && "${force}" != "1" ]]; then
  fail "RW_CODEX_ASSETS_FORCE must be 0 or 1 when set"
fi

if [[ -z "${HOME:-}" ]]; then
  fail "HOME is not set"
fi

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
opencode_root="${config_home}/opencode"
codex_home="${CODEX_HOME:-${HOME}/.codex}"
codex_root="${RW_CODEX_ASSETS_CODEX_ROOT:-${codex_home}/workstation-bootstrap}"

check_only=false

case "${1:-}" in
  "")
    ;;
  --check)
    check_only=true
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage
    fail "unknown argument: ${1}"
    ;;
esac

require_dir() {
  local dir_path="$1"

  if [[ ! -d "${dir_path}" ]]; then
    fail "required template directory not found: ${dir_path}"
  fi
}

require_sources() {
  require_dir "${templates_root}/opencode"
  require_dir "${templates_root}/codex"
}

collect_template_files() {
  local template_dir="$1"
  find "${template_dir}" -type f ! -name '.gitkeep' | sort
}

target_for_source() {
  local template_dir="$1"
  local target_root="$2"
  local source_path="$3"

  printf '%s/%s\n' "${target_root}" "${source_path#${template_dir}/}"
}

ensure_parent_dir() {
  local target_path="$1"
  mkdir -p -- "$(dirname -- "${target_path}")"
}

source_digest() {
  local source_path="$1"
  sha256sum "${source_path}" | awk '{print $1}'
}

target_digest() {
  local target_path="$1"

  if [[ -f "${target_path}" && ! -L "${target_path}" ]]; then
    sha256sum "${target_path}" | awk '{print $1}'
  fi
}

target_state() {
  local source_path="$1"
  local target_path="$2"

  if [[ -L "${target_path}" ]]; then
    local current_target
    current_target="$(readlink -f -- "${target_path}" 2>/dev/null || true)"
    if [[ "${current_target}" == "${source_path}" ]]; then
      echo "linked"
    else
      echo "conflict-symlink"
    fi
    return 0
  fi

  if [[ -d "${target_path}" ]]; then
    echo "conflict-directory"
    return 0
  fi

  if [[ -f "${target_path}" ]]; then
    if [[ "$(target_digest "${target_path}")" == "$(source_digest "${source_path}")" ]]; then
      echo "copied"
    else
      echo "conflict-file"
    fi
    return 0
  fi

  echo "missing"
}

print_status() {
  local label="$1"
  local source_path="$2"
  local target_path="$3"
  local state="$4"

  printf 'install-codex-assets: %s %s -> %s [%s]\n' "${label}" "${source_path}" "${target_path}" "${state}"
}

install_target() {
  local label="$1"
  local source_path="$2"
  local target_path="$3"
  local state

  state="$(target_state "${source_path}" "${target_path}")"
  print_status "${label}" "${source_path}" "${target_path}" "${state}"

  case "${state}" in
    linked|copied)
      return 0
      ;;
    missing)
      if [[ "${check_only}" == true ]]; then
        return 0
      fi

      ensure_parent_dir "${target_path}"
      ln -s -- "${source_path}" "${target_path}"
      return 0
      ;;
    conflict-directory)
      fail "target is an existing directory: ${target_path}"
      ;;
    conflict-symlink|conflict-file)
      if [[ "${check_only}" == true ]]; then
        fail "target would be overwritten: ${target_path}"
      fi

      if [[ "${force}" != "1" ]]; then
        fail "target exists and is not our template file; set RW_CODEX_ASSETS_FORCE=1 to replace it: ${target_path}"
      fi

      if [[ -d "${target_path}" ]]; then
        fail "refusing to replace directory target even with RW_CODEX_ASSETS_FORCE=1: ${target_path}"
      fi

      ensure_parent_dir "${target_path}"
      rm -f -- "${target_path}"
      ln -s -- "${source_path}" "${target_path}"
      printf 'install-codex-assets: replaced %s with symlink to %s\n' "${target_path}" "${source_path}"
      return 0
      ;;
    *)
      fail "unknown target state for ${target_path}: ${state}"
      ;;
  esac
}

install_tree() {
  local label="$1"
  local template_dir="$2"
  local target_root="$3"
  local source_path

  while IFS= read -r source_path; do
    [[ -n "${source_path}" ]] || continue
    install_target "${label}" "${source_path}" "$(target_for_source "${template_dir}" "${target_root}" "${source_path}")"
  done < <(collect_template_files "${template_dir}")
}

require_sources

install_tree "opencode" "${templates_root}/opencode" "${opencode_root}"
install_tree "codex" "${templates_root}/codex" "${codex_root}"

if [[ "${check_only}" == true ]]; then
  printf 'install-codex-assets: check succeeded; no files were changed\n'
else
  printf 'install-codex-assets: asset installation complete\n'
fi
