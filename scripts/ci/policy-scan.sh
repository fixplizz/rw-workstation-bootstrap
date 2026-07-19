#!/usr/bin/env bash

set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"

forbidden='sudo[[:space:]]+npm|apt-key|flatpak[[:space:]]+install[[:space:]]+--system|systemctl[[:space:]]+enable[[:space:]]+ssh|netbird[[:space:]]+up|rustdesk.*password|apparmor.*(disable|stop)|apt(-get)?[[:space:]]+(-y[[:space:]]+)?(dist-)?upgrade'
if grep -RInE "$forbidden" modules install/helpers boot.sh install.sh; then
  printf 'Forbidden workstation policy detected.\n' >&2
  exit 1
fi

bash -c 'source config/sources.rc; fixplizz_validate_sources'
if git grep -nE 'FIXPLIZZ_(REPO|REF|CHANNEL)=.*(private|secret)|rw-workstation-secrets' -- ':!scripts/ci/policy-scan.sh'; then
  printf 'Private configuration boundary violation.\n' >&2
  exit 1
fi

printf 'Policy scan passed.\n'
