#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=remote-base
APT_PACKAGES=()
FLATPAK_APPS=(com.rustdesk.RustDesk)
VERIFY_COMMANDS=(flatpak netbird)
PLANNED_ACTIONS=('install NetBird from official deb822 source' 'install RustDesk and Termix from verified user-scoped Flatpak sources' 'require manual authorization; do not enable SSH or store setup keys')
module_apply_custom() {
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  fixplizz_install_tar_binary netbird "$NETBIRD_URL" "$NETBIRD_SHA256" netbird netbird
  fixplizz_install_flatpak_bundle termix "$TERMIX_URL" "$TERMIX_SHA256"
}
source "$ROOT/install/helpers/module.sh"
