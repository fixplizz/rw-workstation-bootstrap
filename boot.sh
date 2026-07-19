#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=''
if [[ -n ${BASH_SOURCE[0]:-} ]]; then
  ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fi

if [[ -n $ROOT && -r "$ROOT/install/helpers/fixplizz-env.sh" && -r "$ROOT/install/helpers/gate.sh" ]]; then
  # shellcheck source=install/helpers/fixplizz-env.sh
  source "$ROOT/install/helpers/fixplizz-env.sh"
  # shellcheck source=install/helpers/gate.sh
  source "$ROOT/install/helpers/gate.sh"
else
  fixplizz_boot_os_field() {
    local field="$1" os_file="/etc/os-release"
    if [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 && -n ${FIXPLIZZ_OS_RELEASE_FILE:-} ]]; then
      os_file="$FIXPLIZZ_OS_RELEASE_FILE"
    fi
    (
      set +u
      # shellcheck disable=SC1090
      source "$os_file"
      [[ $field == id ]] && printf '%s\n' "${ID:-unknown}" || printf '%s\n' "${VERSION_ID:-unknown}"
    )
  }

  fixplizz_require_supported_environment() {
    local os_id version arch failed=0
    os_id="$(fixplizz_boot_os_field id)"
    version="$(fixplizz_boot_os_field version)"
    if [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 && -n ${FIXPLIZZ_TEST_ARCH:-} ]]; then
      arch="$FIXPLIZZ_TEST_ARCH"
    else
      arch="$(uname -m)"
    fi
    [[ $os_id == ubuntu ]] || {
      printf 'Fixplizz Workstation supports Ubuntu only. Detected OS: %s\n' "$os_id" >&2
      failed=1
    }
    [[ $version == 26.04 ]] || {
      printf 'Fixplizz Workstation requires Ubuntu 26.04 LTS. Detected version: %s\n' "$version" >&2
      failed=1
    }
    [[ $arch == x86_64 ]] || {
      printf 'Fixplizz Workstation supports x86_64 only. Detected architecture: %s\n' "$arch" >&2
      failed=1
    }
    ((failed == 0)) || return 3
  }
fi

fixplizz_require_supported_environment

for prerequisite in git curl mktemp; do
  command -v "$prerequisite" >/dev/null 2>&1 || {
    printf 'Missing bootstrap prerequisite: %s\n' "$prerequisite" >&2
    exit 5
  }
done

if [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 && -z ${FIXPLIZZ_BOOT_SOURCE:-} ]]; then
  [[ -n $ROOT ]] || {
    printf 'FIXPLIZZ_BOOT_SOURCE is required for stdin bootstrap test mode.\n' >&2
    exit 5
  }
  exec "$ROOT/install.sh" "$@"
fi

repo="${FIXPLIZZ_REPO:-fixplizz/rw-workstation-bootstrap}"
ref="${FIXPLIZZ_REF:-v0.1.0-rc3}"
target="${FIXPLIZZ_PATH:-$HOME/.local/share/fixplizz}"
state_home="${FIXPLIZZ_STATE_HOME:-$HOME/.local/state/fixplizz}"
bin_home="${FIXPLIZZ_BIN_HOME:-$HOME/.local/bin}"
temporary="$(mktemp -d "${TMPDIR:-/tmp}/fixplizz-bootstrap.XXXXXX")"
checkout="$temporary/checkout"
backup=""

cleanup_bootstrap() {
  [[ -d $temporary ]] && rm -rf -- "$temporary"
}
trap cleanup_bootstrap EXIT

if [[ -n ${FIXPLIZZ_BOOT_SOURCE:-} ]]; then
  git clone --quiet --no-local "$FIXPLIZZ_BOOT_SOURCE" "$checkout"
  git -C "$checkout" checkout --quiet "$ref"
else
  git clone --quiet --depth 1 --branch "$ref" "https://github.com/$repo.git" "$checkout"
fi

mkdir -p "$(dirname -- "$target")" "$state_home/backups" "$bin_home"
if [[ -e $target || -L $target ]]; then
  backup="$state_home/backups/install-$(date -u +%Y%m%dT%H%M%SZ)-$$"
  mv -- "$target" "$backup"
fi

if ! mv -- "$checkout" "$target"; then
  [[ -n $backup && -e $backup ]] && mv -- "$backup" "$target"
  exit 6
fi

if [[ -e "$bin_home/fixplizz" || -L "$bin_home/fixplizz" ]]; then
  rm -f -- "$bin_home/fixplizz"
fi
ln -s -- "$target/bin/fixplizz" "$bin_home/fixplizz"

trap - EXIT
cleanup_bootstrap
exec "$target/bin/fixplizz" install --profile "${FIXPLIZZ_PROFILE:-mvp}" "$@"
