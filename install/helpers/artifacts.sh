#!/usr/bin/env bash

set -Eeuo pipefail

ARTIFACT_HELPER_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=install/helpers/checksum.sh
source "$ARTIFACT_HELPER_DIR/checksum.sh"

fixplizz_artifact_marker() {
  : "${FIXPLIZZ_STATE_HOME:=$HOME/.local/state/fixplizz}"
  printf '%s/artifacts/%s.sha256\n' "$FIXPLIZZ_STATE_HOME" "$1"
}

fixplizz_artifact_is_current() {
  local name="$1" expected_archive_sha="$2" destination="$3"
  local marker recorded_archive_sha recorded_installed_sha current_installed_sha
  marker="$(fixplizz_artifact_marker "$name")"
  [[ -x $destination && -r $marker ]] || return 1
  read -r recorded_archive_sha recorded_installed_sha <"$marker"
  [[ $recorded_archive_sha == "$expected_archive_sha" ]] || return 1
  current_installed_sha="$(sha256sum "$destination" | awk '{print $1}')"
  [[ $current_installed_sha == "$recorded_installed_sha" ]]
}

fixplizz_mark_artifact_current() {
  local name="$1" archive_sha="$2" destination="$3"
  local marker temporary installed_sha
  marker="$(fixplizz_artifact_marker "$name")"
  mkdir -p "$(dirname -- "$marker")"
  installed_sha="$(sha256sum "$destination" | awk '{print $1}')"
  temporary="$(mktemp "${marker}.XXXXXX")"
  printf '%s %s\n' "$archive_sha" "$installed_sha" >"$temporary"
  mv -f -- "$temporary" "$marker"
}

fixplizz_simple_marker_matches() {
  local name="$1" sha="$2" marker recorded
  marker="$(fixplizz_artifact_marker "$name")"
  [[ -r $marker ]] || return 1
  read -r recorded _ <"$marker"
  [[ $recorded == "$sha" ]]
}

fixplizz_write_simple_marker() {
  local name="$1" sha="$2" marker temporary
  marker="$(fixplizz_artifact_marker "$name")"
  mkdir -p "$(dirname -- "$marker")"
  temporary="$(mktemp "${marker}.XXXXXX")"
  printf '%s verified\n' "$sha" >"$temporary"
  mv -f -- "$temporary" "$marker"
}

fixplizz_download_verified() {
  local name="$1" url="$2" sha="$3" destination="$4"
  local temporary
  [[ $url == https://* ]] || return 1
  fixplizz_artifact_is_current "$name" "$sha" "$destination" && return 0
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
  fixplizz_mark_artifact_current "$name" "$sha" "$destination"
  rm -f "$temporary"
}

fixplizz_install_binary() {
  local name="$1" url="$2" sha="$3" binary_name="$4"
  : "${FIXPLIZZ_BIN_HOME:=$HOME/.local/bin}"
  fixplizz_download_verified "$name" "$url" "$sha" "$FIXPLIZZ_BIN_HOME/$binary_name"
}

fixplizz_install_tar_binary() {
  local name="$1" url="$2" sha="$3" member="$4" binary_name="$5"
  local archive extract_dir destination
  : "${FIXPLIZZ_BIN_HOME:=$HOME/.local/bin}"
  destination="$FIXPLIZZ_BIN_HOME/$binary_name"
  fixplizz_artifact_is_current "$name" "$sha" "$destination" && return 0
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
  mkdir -p "$FIXPLIZZ_BIN_HOME"
  install -m 0755 "$extract_dir/$member" "$destination"
  fixplizz_mark_artifact_current "$name" "$sha" "$destination"
  rm -f "$archive"
  rm -rf "$extract_dir"
}

fixplizz_install_flatpak_bundle() {
  local name="$1" url="$2" sha="$3" app_id="${4:-}"
  local bundle
  if [[ -n $app_id ]] && fixplizz_simple_marker_matches "$name" "$sha" && flatpak info --user "$app_id" >/dev/null 2>&1; then
    return 0
  fi
  bundle="$(mktemp "${TMPDIR:-/tmp}/fixplizz-${name}.XXXXXX.flatpak")"
  curl --fail --location --proto '=https' --tlsv1.2 --retry 3 --output "$bundle" "$url"
  if ! fixplizz_verify_sha256 "$bundle" "$sha"; then
    rm -f "$bundle"
    return 1
  fi
  flatpak install --user --noninteractive -y "$bundle"
  fixplizz_write_simple_marker "$name" "$sha"
  rm -f "$bundle"
}

fixplizz_install_zip_fonts() {
  local name="$1" url="$2" sha="$3"
  local archive extract_dir font_dir font
  font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/fixplizz-$name"
  if fixplizz_simple_marker_matches "$name" "$sha" && find "$font_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) -print -quit 2>/dev/null | grep -q .; then
    return 0
  fi
  archive="$(mktemp "${TMPDIR:-/tmp}/fixplizz-${name}.XXXXXX.zip")"
  extract_dir="$(mktemp -d "${TMPDIR:-/tmp}/fixplizz-${name}.XXXXXX")"
  if ! curl --fail --location --proto '=https' --tlsv1.2 --retry 3 --output "$archive" "$url" ||
    ! fixplizz_verify_sha256 "$archive" "$sha"; then
    rm -f "$archive"
    rm -rf "$extract_dir"
    return 1
  fi
  unzip -q "$archive" -d "$extract_dir"
  mkdir -p "$font_dir"
  while IFS= read -r -d '' font; do
    install -m 0644 "$font" "$font_dir/$(basename -- "$font")"
  done < <(find "$extract_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) -print0)
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null
  fixplizz_write_simple_marker "$name" "$sha"
  rm -f "$archive"
  rm -rf "$extract_dir"
}
