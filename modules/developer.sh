#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=developer
APT_PACKAGES=(gh pipx sqlite3 postgresql-client redis-tools golang-go nodejs npm rustc cargo)
FLATPAK_APPS=()
VERIFY_COMMANDS=(gh mise uv node pnpm python3 go rustc cargo pipx sqlite3 psql redis-cli)
PLANNED_ACTIONS=('add official GitHub CLI deb822 source' 'install pinned mise and uv artifacts' 'install Node.js LTS through mise' 'enable pnpm through Corepack' 'install Rust through rustup without modifying system Python')
module_apply_custom() {
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  fixplizz_install_binary mise "$MISE_URL" "$MISE_SHA256" mise
  fixplizz_install_tar_binary uv "$UV_URL" "$UV_SHA256" uv-x86_64-unknown-linux-gnu/uv uv
  "$FIXPLIZZ_BIN_HOME/mise" use --global node@lts
  "$HOME/.local/share/mise/shims/corepack" enable
  "$HOME/.local/share/mise/shims/corepack" prepare "pnpm@$PNPM_VERSION" --activate
}
source "$ROOT/install/helpers/module.sh"
