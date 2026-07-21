#!/bin/bash

set -Eeuo pipefail

fixplizz_apt_install() {
  (($# > 0)) || return 0
  if [[ ${FIXPLIZZ_TEST_MODE:-0} == "1" ]]; then
    return 0
  fi
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends "$@"
}
