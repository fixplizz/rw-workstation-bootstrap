#!/bin/bash

set -Eeuo pipefail

fixplizz_flatpak_install() {
  (($# > 0)) || return 0
  if [[ ${FIXPLIZZ_TEST_MODE:-0} == "1" ]]; then
    return 0
  fi
  if ! flatpak remote-list --user --columns=name | grep -Fxq flathub; then
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
  flatpak install --user --noninteractive -y flathub "$@"
}
