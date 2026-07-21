#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=ai-base
APT_PACKAGES=()
FLATPAK_APPS=()
VERIFY_COMMANDS=(codex opencode hermes orca-ide)
PLANNED_ACTIONS=('install pinned Codex CLI in user prefix' 'install pinned OpenCode CLI artifact with checksum' 'install pinned Hermes Agent wheel with checksum in an isolated uv tool environment' 'install pinned Orca desktop agent IDE package with checksum' 'disable anonymous Orca telemetry through the user environment' 'do not create credentials or global AI configuration')
module_apply_custom() {
  local installed_codex_version='' orca_environment
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  if command -v codex >/dev/null 2>&1; then
    installed_codex_version="$(codex --version 2>/dev/null || true)"
  fi
  if [[ " $installed_codex_version " != *" $CODEX_VERSION "* ]]; then
    npm install --global --prefix "$HOME/.local" "@openai/codex@$CODEX_VERSION"
  fi
  fixplizz_install_tar_binary opencode "$OPENCODE_URL" "$OPENCODE_SHA256" opencode opencode
  fixplizz_install_uv_tool hermes-agent "$HERMES_AGENT_URL" "$HERMES_AGENT_SHA256" "$HERMES_AGENT_PYTHON_VERSION" hermes
  fixplizz_install_deb_artifact orca "$ORCA_URL" "$ORCA_SHA256"
  orca_environment="$HOME/.config/environment.d/90-fixplizz-orca.conf"
  mkdir -p "$(dirname -- "$orca_environment")"
  if [[ ! -r $orca_environment ]] || [[ $(<"$orca_environment") != 'ORCA_TELEMETRY_DISABLED=1' ]]; then
    [[ -e $orca_environment ]] && fixplizz_backup_path "$orca_environment" >/dev/null
    printf 'ORCA_TELEMETRY_DISABLED=1\n' >"$orca_environment"
    chmod 0644 "$orca_environment"
  fi
}
source "$ROOT/install/helpers/module.sh"
