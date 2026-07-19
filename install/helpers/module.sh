#!/bin/bash

set -Eeuo pipefail

# shellcheck source=install/helpers/packages.sh
source "$FIXPLIZZ_ROOT/install/helpers/packages.sh"
# shellcheck source=install/helpers/flatpak.sh
source "$FIXPLIZZ_ROOT/install/helpers/flatpak.sh"

module_plan() {
  local item
  printf 'module\t%s\n' "$MODULE_NAME"
  for item in "${APT_PACKAGES[@]:-}"; do
    [[ -n $item ]] && printf 'package\tubuntu\t%s\n' "$item"
  done
  for item in "${FLATPAK_APPS[@]:-}"; do
    [[ -n $item ]] && printf 'flatpak\tflathub-user\t%s\n' "$item"
  done
  for item in "${PLANNED_ACTIONS[@]:-}"; do
    [[ -n $item ]] && printf 'action\t%s\n' "$item"
  done
}

module_check() {
  local command
  for command in "${VERIFY_COMMANDS[@]:-}"; do
    [[ -z $command ]] && continue
    command -v "$command" >/dev/null 2>&1 || return 1
  done
}

module_apply() {
  fixplizz_apt_install "${APT_PACKAGES[@]:-}"
  fixplizz_flatpak_install "${FLATPAK_APPS[@]:-}"
  if declare -F module_apply_custom >/dev/null; then
    module_apply_custom
  fi
}

module_verify() {
  if [[ ${FIXPLIZZ_TEST_MODE:-0} == "1" ]]; then
    return 0
  fi
  module_check
}

case "${1:-}" in
  plan) module_plan ;;
  check) module_check ;;
  apply) module_apply ;;
  verify) module_verify ;;
  *)
    printf 'Usage: %s {plan|check|apply|verify}\n' "$0" >&2
    exit 2
    ;;
esac
