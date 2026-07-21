#!/bin/bash

set -Eeuo pipefail

fixplizz_render_deb822() {
  local name="$1" uri="$2" suite="$3" components="$4" keyring="$5"
  [[ $name =~ ^[a-z0-9][a-z0-9-]*$ ]] || return 4
  [[ $uri == https://* ]] || {
    printf 'Repository %s must use HTTPS.\n' "$name" >&2
    return 4
  }
  [[ $keyring == /etc/apt/keyrings/* ]] || {
    printf 'Repository %s must use a dedicated /etc/apt/keyrings key.\n' "$name" >&2
    return 4
  }
  cat <<EOF
Types: deb
URIs: $uri
Suites: $suite
Components: $components
Architectures: amd64
Signed-By: $keyring
EOF
}

fixplizz_install_deb822_source() {
  local name="$1" uri="$2" suite="$3" components="$4" keyring="$5"
  local destination="/etc/apt/sources.list.d/$name.sources"
  local desired
  desired="$(fixplizz_render_deb822 "$name" "$uri" "$suite" "$components" "$keyring")"
  if [[ ${FIXPLIZZ_TEST_MODE:-0} == "1" ]]; then
    return 0
  fi
  if [[ -r $destination ]] && [[ $(<"$destination") == "$desired" ]]; then
    return 0
  fi
  printf '%s\n' "$desired" | sudo tee "$destination" >/dev/null
}
