#!/usr/bin/env bash

set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"

pattern='BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|(^|[^[:alnum:]_])(api[_-]?key|access[_-]?token|client[_-]?secret)[[:space:]]*=[[:space:]]*[^$[:space:]<{]'
if grep -RInE "$pattern" . --exclude-dir=.git --exclude='*.png' --exclude='*.jpg' --exclude='*.jpeg'; then
  printf 'Potential credential material found in the public tree.\n' >&2
  exit 1
fi

if git ls-files | grep -E '(^|/)(\.env($|\.)|id_(rsa|ed25519)$|credentials?\.(json|ya?ml)$|secrets?\.(json|ya?ml)$)'; then
  printf 'Credential-like filename found in the public tree.\n' >&2
  exit 1
fi

printf 'Secrets boundary scan passed.\n'
