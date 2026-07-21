#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -z ${FIXPLIZZ_ROOT:-} ]]; then
  # shellcheck source=install/helpers/fixplizz-env.sh
  source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/fixplizz-env.sh"
fi

# shellcheck source=install/helpers/detection.sh
source "$FIXPLIZZ_ROOT/install/helpers/detection.sh"

FIXPLIZZ_EXIT_ENVIRONMENT=3

fixplizz_supported_environment_errors() {
  local os_id version arch
  os_id="$(fixplizz_detect_os)"
  version="$(fixplizz_detect_version)"
  arch="$(fixplizz_detect_arch)"

  [[ "$os_id" == "ubuntu" ]] || printf 'Fixplizz Workstation supports Ubuntu only. Detected OS: %s\n' "$os_id"
  [[ "$version" == "26.04" ]] || printf 'Fixplizz Workstation requires Ubuntu 26.04 LTS. Detected version: %s\n' "$version"
  [[ "$arch" == "x86_64" ]] || printf 'Fixplizz Workstation supports x86_64 only. Detected architecture: %s\n' "$arch"
}

fixplizz_is_supported_environment() {
  [[ -z "$(fixplizz_supported_environment_errors)" ]]
}

fixplizz_require_supported_environment() {
  local errors
  errors="$(fixplizz_supported_environment_errors)"

  if [[ -n "$errors" ]]; then
    printf '%s\n' "$errors" >&2
    return "$FIXPLIZZ_EXIT_ENVIRONMENT"
  fi
}
