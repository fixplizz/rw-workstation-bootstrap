#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=install/helpers/fixplizz-env.sh
source "$ROOT/install/helpers/fixplizz-env.sh"
# shellcheck source=install/helpers/gate.sh
source "$ROOT/install/helpers/gate.sh"

fixplizz_require_supported_environment
fixplizz_create_user_dirs

if [[ ! -e "$FIXPLIZZ_BIN" ]]; then
  ln -s "$ROOT/bin/fixplizz" "$FIXPLIZZ_BIN"
fi

cat <<EOF
Fixplizz Workstation PR 1 bootstrap complete.

Installed CLI:
  $FIXPLIZZ_BIN

This PR 1 bootstrap does not run the full workstation installer.
Run diagnostics with:
  fixplizz doctor
EOF
