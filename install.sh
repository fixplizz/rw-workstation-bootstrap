#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=install/helpers/fixplizz-env.sh
source "$ROOT/install/helpers/fixplizz-env.sh"
# shellcheck source=install/helpers/gate.sh
source "$ROOT/install/helpers/gate.sh"

fixplizz_require_supported_environment
fixplizz_create_user_dirs

exec "$ROOT/bin/fixplizz" install --profile "${FIXPLIZZ_PROFILE:-mvp}" "$@"
