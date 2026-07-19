#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=ai-base
APT_PACKAGES=()
FLATPAK_APPS=()
VERIFY_COMMANDS=(codex opencode)
PLANNED_ACTIONS=('install pinned Codex CLI in user prefix' 'install pinned OpenCode CLI artifact with checksum' 'do not create credentials or global AI configuration')
module_apply_custom() {
  local installed_codex_version=''
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  if command -v codex >/dev/null 2>&1; then
    installed_codex_version="$(codex --version 2>/dev/null || true)"
  fi
  if [[ " $installed_codex_version " != *" $CODEX_VERSION "* ]]; then
    npm install --prefix "$HOME/.local" "@openai/codex@$CODEX_VERSION"
  fi
  fixplizz_install_tar_binary opencode "$OPENCODE_URL" "$OPENCODE_SHA256" opencode opencode
}
source "$ROOT/install/helpers/module.sh"
