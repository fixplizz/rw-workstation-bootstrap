#!/usr/bin/env bash

set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
execute=false
[[ ${1:-} == --execute ]] && execute=true

"$ROOT/bin/fixplizz" doctor
"$ROOT/bin/fixplizz" install --profile mvp --dry-run

if [[ $execute != true ]]; then
  printf 'Preflight complete. Re-run with --execute on a disposable native Ubuntu 26.04 Desktop amd64 machine.\n'
  exit 0
fi

[[ ${FIXPLIZZ_NATIVE_SMOKE_ACK:-} == 'ubuntu-26.04-disposable' ]] || {
  printf 'Set FIXPLIZZ_NATIVE_SMOKE_ACK=ubuntu-26.04-disposable to confirm the native test host.\n' >&2
  exit 2
}

"$ROOT/bin/fixplizz" install --profile mvp --noninteractive
"$ROOT/bin/fixplizz" doctor
"$ROOT/bin/fixplizz" status --json | python3 -m json.tool
printf 'Native smoke commands completed. Manual GNOME, logout, reboot, Docker and GUI checks remain; record them in the report template.\n'
