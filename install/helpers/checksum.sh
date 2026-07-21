#!/bin/bash

set -Eeuo pipefail

fixplizz_verify_sha256() {
  local file="$1" expected="$2" actual
  [[ $expected =~ ^[0-9a-fA-F]{64}$ ]] || {
    printf 'Invalid SHA-256 value.\n' >&2
    return 4
  }
  [[ -f $file ]] || {
    printf 'Artifact does not exist: %s\n' "$file" >&2
    return 1
  }
  actual="$(sha256sum "$file" | awk '{print $1}')"
  if [[ ${actual,,} != "${expected,,}" ]]; then
    printf 'SHA-256 verification failed for %s.\n' "$file" >&2
    return 1
  fi
}
