#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=install/helpers/fixplizz-env.sh
source "$ROOT/install/helpers/fixplizz-env.sh"
# shellcheck source=install/helpers/gate.sh
source "$ROOT/install/helpers/gate.sh"

fixplizz_require_supported_environment

for prerequisite in git curl mktemp; do
  command -v "$prerequisite" >/dev/null 2>&1 || {
    printf 'Missing bootstrap prerequisite: %s\n' "$prerequisite" >&2
    exit 5
  }
done

if [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 && -z ${FIXPLIZZ_BOOT_SOURCE:-} ]]; then
  exec "$ROOT/install.sh" "$@"
fi

repo="${FIXPLIZZ_REPO:-fixplizz/rw-workstation-bootstrap}"
ref="${FIXPLIZZ_REF:-mvp/one-command-workstation}"
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
  git clone --quiet --no-local --branch "$ref" "$FIXPLIZZ_BOOT_SOURCE" "$checkout"
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
