#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=developer
APT_PACKAGES=(gh pipx sqlite3 postgresql-client redis-tools golang-go nodejs npm rustc cargo clang cmake pkg-config python3-dev)
FLATPAK_APPS=()
VERIFY_COMMANDS=(gh mise uv node npm npx corepack pnpm yarn tsc tsx eslint prettier vitest python3 go rustc cargo pipx sqlite3 psql redis-cli)
PLANNED_ACTIONS=('install GitHub CLI from Ubuntu' 'install pinned mise and uv artifacts' 'install Node.js LTS through mise' 'install pinned Corepack, pnpm, and Yarn in the user prefix' 'install pinned TypeScript, tsx, ESLint, Prettier, and Vitest in the user prefix' 'install native Node.js build prerequisites: clang, CMake, pkg-config, and Python headers' 'install Ubuntu Rust toolchain without modifying system Python')
module_apply_custom() {
  local npm_binary corepack_binary
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  fixplizz_install_binary mise "$MISE_URL" "$MISE_SHA256" mise
  fixplizz_install_tar_binary uv "$UV_URL" "$UV_SHA256" uv-x86_64-unknown-linux-gnu/uv uv
  "$FIXPLIZZ_BIN_HOME/mise" use --global node@lts
  npm_binary="$HOME/.local/share/mise/shims/npm"
  "$npm_binary" install --global --prefix "$HOME/.local" \
    "corepack@$COREPACK_VERSION" \
    "typescript@$TYPESCRIPT_VERSION" \
    "tsx@$TSX_VERSION" \
    "eslint@$ESLINT_VERSION" \
    "prettier@$PRETTIER_VERSION" \
    "vitest@$VITEST_VERSION"
  corepack_binary="$FIXPLIZZ_BIN_HOME/corepack"
  "$corepack_binary" enable --install-directory "$FIXPLIZZ_BIN_HOME"
  "$corepack_binary" prepare "pnpm@$PNPM_VERSION" --activate
  "$corepack_binary" prepare "yarn@$YARN_VERSION" --activate
}
source "$ROOT/install/helpers/module.sh"
