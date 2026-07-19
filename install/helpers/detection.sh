#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -z ${FIXPLIZZ_ROOT:-} ]]; then
  # shellcheck source=install/helpers/fixplizz-env.sh
  source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/fixplizz-env.sh"
fi

fixplizz_test_mode_enabled() {
  [[ ${FIXPLIZZ_TEST_MODE:-0} == "1" ]]
}

fixplizz_os_release_file() {
  if fixplizz_test_mode_enabled && [[ -n ${FIXPLIZZ_OS_RELEASE_FILE:-} ]]; then
    printf '%s\n' "$FIXPLIZZ_OS_RELEASE_FILE"
  else
    printf '/etc/os-release\n'
  fi
}

fixplizz_read_os_field() {
  local field="$1"
  local file
  file="$(fixplizz_os_release_file)"

  [[ -r "$file" ]] || return 1

  (
    set +u
    # shellcheck disable=SC1090
    source "$file"
    case "$field" in
      id)
        printf '%s\n' "${ID:-unknown}"
        ;;
      version)
        printf '%s\n' "${VERSION_ID:-unknown}"
        ;;
      *)
        return 1
        ;;
    esac
  )
}

fixplizz_detect_os() {
  fixplizz_read_os_field id || printf 'unknown\n'
}

fixplizz_detect_version() {
  fixplizz_read_os_field version || printf 'unknown\n'
}

fixplizz_detect_arch() {
  if fixplizz_test_mode_enabled && [[ -n ${FIXPLIZZ_TEST_ARCH:-} ]]; then
    printf '%s\n' "$FIXPLIZZ_TEST_ARCH"
  else
    uname -m
  fi
}

fixplizz_detect_desktop() {
  if fixplizz_test_mode_enabled && [[ -n ${FIXPLIZZ_TEST_DESKTOP:-} ]]; then
    printf '%s\n' "$FIXPLIZZ_TEST_DESKTOP"
  else
    printf '%s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
  fi
}

fixplizz_detect_session() {
  if fixplizz_test_mode_enabled && [[ -n ${FIXPLIZZ_TEST_SESSION:-} ]]; then
    printf '%s\n' "$FIXPLIZZ_TEST_SESSION"
  else
    printf '%s\n' "${XDG_SESSION_TYPE:-unknown}"
  fi
}

fixplizz_has_command() {
  command -v "$1" >/dev/null 2>&1
}

fixplizz_detect_legacy_installation() {
  local found=()

  [[ -d "$HOME/.local/share/omakub" ]] && found+=("$HOME/.local/share/omakub")
  [[ -d "$HOME/.local/share/omabuntu" ]] && found+=("$HOME/.local/share/omabuntu")

  if ((${#found[@]} == 0)); then
    printf 'none\n'
  else
    local item
    for item in "${found[@]}"; do
      printf '%s\n' "$item"
    done
  fi
}
