#!/usr/bin/env bash

set -Eeuo pipefail

fixplizz_helper_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd
}

fixplizz_repo_root() {
  local helper_dir
  helper_dir="$(fixplizz_helper_dir)"
  cd -- "$helper_dir/../.." && pwd
}

export FIXPLIZZ_BRAND="${FIXPLIZZ_BRAND:-Fixplizz Workstation}"
export FIXPLIZZ_REPO="${FIXPLIZZ_REPO:-fixplizz/rw-workstation-bootstrap}"
export FIXPLIZZ_REF="${FIXPLIZZ_REF:-v0.1.0-rc5}"
export FIXPLIZZ_CHANNEL="${FIXPLIZZ_CHANNEL:-rc}"
export FIXPLIZZ_PROFILE="${FIXPLIZZ_PROFILE:-mvp}"
export FIXPLIZZ_NONINTERACTIVE="${FIXPLIZZ_NONINTERACTIVE:-1}"
export FIXPLIZZ_DRY_RUN="${FIXPLIZZ_DRY_RUN:-0}"
export FIXPLIZZ_LOG_LEVEL="${FIXPLIZZ_LOG_LEVEL:-info}"

export FIXPLIZZ_ROOT="${FIXPLIZZ_ROOT:-$(fixplizz_repo_root)}"
export FIXPLIZZ_PATH="${FIXPLIZZ_PATH:-$HOME/.local/share/fixplizz}"
export FIXPLIZZ_STATE_HOME="${FIXPLIZZ_STATE_HOME:-$HOME/.local/state/fixplizz}"
export FIXPLIZZ_CONFIG_HOME="${FIXPLIZZ_CONFIG_HOME:-$HOME/.config/fixplizz}"
export FIXPLIZZ_CACHE_HOME="${FIXPLIZZ_CACHE_HOME:-$HOME/.cache/fixplizz}"
export FIXPLIZZ_BIN_HOME="${FIXPLIZZ_BIN_HOME:-$HOME/.local/bin}"
export FIXPLIZZ_BIN="${FIXPLIZZ_BIN:-$FIXPLIZZ_BIN_HOME/fixplizz}"
export FIXPLIZZ_LOG_DIR="${FIXPLIZZ_LOG_DIR:-/var/log/fixplizz}"
export FIXPLIZZ_LIB_DIR="${FIXPLIZZ_LIB_DIR:-/var/lib/fixplizz}"

case ":$PATH:" in
  *":$FIXPLIZZ_BIN_HOME:"*) ;;
  *) export PATH="$FIXPLIZZ_BIN_HOME:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/.local/share/mise/shims:"*) ;;
  *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
esac

fixplizz_version() {
  if [[ -r "$FIXPLIZZ_ROOT/version" ]]; then
    tr -d '[:space:]' <"$FIXPLIZZ_ROOT/version"
  else
    printf '0.0.0-pr1\n'
  fi
}

fixplizz_create_user_dirs() {
  mkdir -p "$FIXPLIZZ_PATH" "$FIXPLIZZ_STATE_HOME" "$FIXPLIZZ_CONFIG_HOME" "$FIXPLIZZ_CACHE_HOME" "$FIXPLIZZ_BIN_HOME"
}
