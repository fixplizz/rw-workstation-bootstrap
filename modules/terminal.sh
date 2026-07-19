#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=terminal
APT_PACKAGES=(alacritty tmux fzf btop)
FLATPAK_APPS=()
VERIFY_COMMANDS=(alacritty tmux fzf btop starship zoxide)
PLANNED_ACTIONS=('install pinned Starship artifact with checksum' 'install pinned zoxide artifact with checksum' 'install pinned Nerd Font with checksum' 'backup shell rc and add managed Fixplizz source line')
source "$ROOT/install/helpers/module.sh"
