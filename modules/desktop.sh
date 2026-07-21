#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=desktop
APT_PACKAGES=()
FLATPAK_APPS=()
VERIFY_COMMANDS=(gsettings)
PLANNED_ACTIONS=('create ~/Applications' 'apply guarded GNOME workspace, calendar, dock and AppIndicator defaults')
module_apply_custom() {
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  mkdir -p "$HOME/Applications"
  if [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]]; then
    gsettings writable org.gnome.desktop.wm.preferences num-workspaces >/dev/null 2>&1 &&
      gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
    gsettings writable org.gnome.shell.extensions.dash-to-dock click-action >/dev/null 2>&1 &&
      gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize
  fi
}
source "$ROOT/install/helpers/module.sh"
