#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=ai-base
APT_PACKAGES=()
FLATPAK_APPS=()
VERIFY_COMMANDS=(codex opencode)
PLANNED_ACTIONS=('install pinned Codex CLI in user prefix' 'install pinned OpenCode CLI artifact with checksum' 'do not create credentials or global AI configuration')
source "$ROOT/install/helpers/module.sh"
