#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=install/helpers/fixplizz-env.sh
source "$ROOT/install/helpers/fixplizz-env.sh"
# shellcheck source=install/helpers/gate.sh
source "$ROOT/install/helpers/gate.sh"

fixplizz_require_supported_environment
fixplizz_create_user_dirs

cat <<'EOF'
Fixplizz Workstation PR 1 install path is intentionally limited.

The inherited full Omabuntu workstation installation flow is disabled by default
and will be adapted in later PRs.
EOF
