#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=developer
APT_PACKAGES=(pipx sqlite3 postgresql-client redis-tools golang-go)
FLATPAK_APPS=()
VERIFY_COMMANDS=(gh mise uv node pnpm python3 go rustc cargo pipx sqlite3 psql redis-cli)
PLANNED_ACTIONS=('add official GitHub CLI deb822 source' 'install pinned mise and uv artifacts' 'install Node.js LTS through mise' 'enable pnpm through Corepack' 'install Rust through rustup without modifying system Python')
source "$ROOT/install/helpers/module.sh"
