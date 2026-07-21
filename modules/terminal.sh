#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=terminal
APT_PACKAGES=(alacritty tmux fzf btop)
FLATPAK_APPS=()
VERIFY_COMMANDS=(alacritty tmux fzf btop starship zoxide herdr)
PLANNED_ACTIONS=('install pinned Starship artifact with checksum' 'install pinned zoxide artifact with checksum' 'install pinned herdr agent dashboard with checksum' 'install pinned Nerd Font with checksum' 'backup shell rc and add managed Fixplizz source line with h and agents aliases')
module_apply_custom() {
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  fixplizz_install_tar_binary starship "$STARSHIP_URL" "$STARSHIP_SHA256" starship starship
  fixplizz_install_tar_binary zoxide "$ZOXIDE_URL" "$ZOXIDE_SHA256" zoxide zoxide
  fixplizz_install_binary herdr "$HERDR_URL" "$HERDR_SHA256" herdr
  fixplizz_install_zip_fonts jetbrains-mono "$NERD_FONT_URL" "$NERD_FONT_SHA256"
  mkdir -p "$HOME/.config/herdr"
  fixplizz_install_shell_integration "$HOME/.bashrc"
}
source "$ROOT/install/helpers/module.sh"
