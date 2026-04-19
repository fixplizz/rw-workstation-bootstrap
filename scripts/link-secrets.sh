#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ -z "${ROOT_DIR:-}" ]]; then
  ROOT_DIR="$(cd "${script_dir}/.." && pwd -P)"
else
  ROOT_DIR="$(cd -P -- "${ROOT_DIR}" && pwd -P)"
fi

SECRETS_DIR="${RW_SECRETS_DIR:-/home/fixplizz/projects/rw-omniroute/rw-workstation-secrets}"

OMNIROUTE_SOURCE="${SECRETS_DIR}/env/omniroute/.env"
OMNIROUTE_TARGET="${ROOT_DIR}/bootstrap/omniroute/.env.local"
TARGET_ALREADY_LINKED=false

usage() {
  echo "Usage: $(basename "$0") [--check]" >&2
}

fail() {
  echo "link-secrets: $1" >&2
  exit 1
}

check_paths() {
  if [[ ! -d "${ROOT_DIR}" ]]; then
    fail "bootstrap root directory not found: ${ROOT_DIR}"
  fi

  if [[ ! -d "${SECRETS_DIR}" ]]; then
    fail "secrets directory not found: ${SECRETS_DIR}"
  fi

  if [[ ! -f "${OMNIROUTE_SOURCE}" ]]; then
    fail "required OmniRoute env file not found: ${OMNIROUTE_SOURCE}"
  fi
}

validate_target_parent() {
  local root_real
  local target_parent
  local existing_ancestor
  local existing_real

  if ! root_real="$(cd -P -- "${ROOT_DIR}" && pwd -P)"; then
    fail "unable to resolve bootstrap root: ${ROOT_DIR}"
  fi

  target_parent="$(dirname -- "${OMNIROUTE_TARGET}")"

  if [[ -L "${target_parent}" ]]; then
    fail "target parent directory is a symlink: ${target_parent}"
  fi

  existing_ancestor="${target_parent}"
  while [[ ! -e "${existing_ancestor}" ]]; do
    existing_ancestor="$(dirname -- "${existing_ancestor}")"
  done

  if [[ ! -d "${existing_ancestor}" ]]; then
    fail "target path ancestor is not a directory: ${existing_ancestor}"
  fi

  if ! existing_real="$(cd -P -- "${existing_ancestor}" && pwd -P)"; then
    fail "unable to resolve target path ancestor: ${existing_ancestor}"
  fi

  case "${existing_real}" in
    "${root_real}"|"${root_real}"/*)
      ;;
    *)
      fail "target parent escapes bootstrap root through symlinked ancestor: ${target_parent} -> ${existing_real}"
      ;;
  esac
}

validate_target_state() {
  if [[ -L "${OMNIROUTE_TARGET}" ]]; then
    local current_target

    if ! current_target="$(readlink -- "${OMNIROUTE_TARGET}")"; then
      fail "unable to read target symlink: ${OMNIROUTE_TARGET}"
    fi

    if [[ "${current_target}" == "${OMNIROUTE_SOURCE}" ]]; then
      TARGET_ALREADY_LINKED=true
      echo "link-secrets: OmniRoute env already linked ${OMNIROUTE_TARGET} -> ${OMNIROUTE_SOURCE}"
      return 0
    fi

    fail "target symlink points elsewhere: ${OMNIROUTE_TARGET} -> ${current_target}"
  fi

  if [[ -e "${OMNIROUTE_TARGET}" ]]; then
    fail "target already exists and is not a symlink: ${OMNIROUTE_TARGET}"
  fi
}

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

check_paths
validate_target_parent
validate_target_state

echo "link-secrets: validated secrets directory ${SECRETS_DIR}"
echo "link-secrets: validated OmniRoute env source ${OMNIROUTE_SOURCE}"
echo "link-secrets: target OmniRoute env ${OMNIROUTE_TARGET}"

if [[ "${check_only}" == true ]]; then
  echo "link-secrets: check succeeded; no files were changed"
  exit 0
fi

if [[ "${TARGET_ALREADY_LINKED}" == true ]]; then
  echo "link-secrets: no changes needed"
  exit 0
fi

mkdir -p -- "$(dirname -- "${OMNIROUTE_TARGET}")"

ln -s -- "${OMNIROUTE_SOURCE}" "${OMNIROUTE_TARGET}"
echo "link-secrets: linked OmniRoute env ${OMNIROUTE_TARGET} -> ${OMNIROUTE_SOURCE}"
