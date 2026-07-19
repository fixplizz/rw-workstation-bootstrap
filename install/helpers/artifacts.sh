#!/usr/bin/env bash

set -Eeuo pipefail

ARTIFACT_HELPER_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=install/helpers/checksum.sh
source "$ARTIFACT_HELPER_DIR/checksum.sh"

fixplizz_download_verified() {
  local name="$1" url="$2" sha="$3" destination="$4"
  local temporary
  [[ $url == https://* ]] || return 1
  temporary="$(mktemp "${TMPDIR:-/tmp}/fixplizz-${name}.XXXXXX")"
  if [[ -n ${FIXPLIZZ_TEST_DOWNLOAD_FILE:-} ]]; then
    cp -- "$FIXPLIZZ_TEST_DOWNLOAD_FILE" "$temporary"
  else
    curl --fail --location --proto '=https' --tlsv1.2 --retry 3 --output "$temporary" "$url"
  fi
  if ! fixplizz_verify_sha256 "$temporary" "$sha"; then
    rm -f "$temporary"
    return 1
  fi
  mkdir -p "$(dirname -- "$destination")"
  install -m 0755 "$temporary" "$destination"
  rm -f "$temporary"
}

fixplizz_install_binary() {
  local name="$1" url="$2" sha="$3" binary_name="$4"
  : "${FIXPLIZZ_BIN_HOME:=$HOME/.local/bin}"
  fixplizz_download_verified "$name" "$url" "$sha" "$FIXPLIZZ_BIN_HOME/$binary_name"
}

fixplizz_install_tar_binary() {
  local name="$1" url="$2" sha="$3" member="$4" binary_name="$5"
  local archive extract_dir
  archive="$(mktemp "${TMPDIR:-/tmp}/fixplizz-${name}.XXXXXX.tar.gz")"
  extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/fixplizz-${name}.XXXXXX")"
  if [[ -n ${FIXPLIZZ_TEST_DOWNLOAD_FILE:-} ]]; then
    cp -- "$FIXPLIZZ_TEST_DOWNLOAD_FILE" "$archive"
  else
    curl --fail --location --proto '=https' --tlsv1.2 --retry 3 --output "$archive" "$url"
  fi
  if ! fixplizz_verify_sha256 "$archive" "$sha"; then
    rm -f "$archive"
    rm -rf "$extract_dir"
    return 1
  fi
  tar -xzf "$archive" -C "$extract_dir" "$member"
  mkdir -p "${FIXPLIZZ_BIN_HOME:=$HOME/.local/bin}"
  install -m 0755 "$extract_dir/$member" "$FIXPLIZZ_BIN_HOME/$binary_name"
  rm -f "$archive"
  rm -rf "$extract_dir"
}

fixplizz_install_flatpak_bundle() {
  local name="$1" url="$2" sha="$3"
  local bundle
  bundle="$(mktemp "${TMPDIR:-/tmp}/fixplizz-${name}.XXXXXX.flatpak")"
  curl --fail --location --proto '=https' --tlsv1.2 --retry 3 --output "$bundle" "$url"
  if ! fixplizz_verify_sha256 "$bundle" "$sha"; then
    rm -f "$bundle"
    return 1
  fi
  flatpak install --user --noninteractive -y "$bundle"
  rm -f "$bundle"
}
