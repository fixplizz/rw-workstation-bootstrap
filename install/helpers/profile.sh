#!/bin/bash

set -Eeuo pipefail

fixplizz_profile_file() {
  local profile="$1"
  [[ $profile =~ ^[a-z0-9][a-z0-9-]*$ ]] || return 1
  printf '%s/profiles/%s\n' "$FIXPLIZZ_ROOT" "$profile"
}

fixplizz_profile_exists() {
  local file
  file="$(fixplizz_profile_file "$1")" || return 1
  [[ -r $file ]]
}

fixplizz_profile_modules() {
  local file
  file="$(fixplizz_profile_file "$1")" || return 1
  [[ -r $file ]] || return 1
  sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}
