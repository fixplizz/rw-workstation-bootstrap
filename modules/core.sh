#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=core
APT_PACKAGES=(git curl wget ca-certificates gnupg jq yq rsync unzip zip build-essential ripgrep fd-find fzf bat btop tmux direnv shellcheck shfmt flatpak ufw openssh-client wl-clipboard)
FLATPAK_APPS=()
VERIFY_COMMANDS=(git curl wget jq rsync unzip zip rg fzf btop tmux direnv shellcheck shfmt flatpak ssh wl-copy)
PLANNED_ACTIONS=('symlink ~/.local/bin/fd -> /usr/bin/fdfind' 'symlink ~/.local/bin/bat -> /usr/bin/batcat')
module_apply_custom() {
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  fixplizz_managed_symlink /usr/bin/fdfind "$FIXPLIZZ_BIN_HOME/fd"
  fixplizz_managed_symlink /usr/bin/batcat "$FIXPLIZZ_BIN_HOME/bat"
}
source "$ROOT/install/helpers/module.sh"
