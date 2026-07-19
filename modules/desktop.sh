#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd); export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=desktop
APT_PACKAGES=()
FLATPAK_APPS=()
VERIFY_COMMANDS=(gsettings)
PLANNED_ACTIONS=('create ~/Applications' 'apply guarded GNOME workspace, calendar, dock and AppIndicator defaults')
source "$ROOT/install/helpers/module.sh"
