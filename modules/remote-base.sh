#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=remote-base
APT_PACKAGES=()
FLATPAK_APPS=(com.rustdesk.RustDesk)
VERIFY_COMMANDS=(flatpak netbird)
PLANNED_ACTIONS=('install NetBird from official deb822 source' 'install RustDesk and Termix from verified user-scoped Flatpak sources' 'require manual authorization; do not enable SSH or store setup keys')
source "$ROOT/install/helpers/module.sh"
