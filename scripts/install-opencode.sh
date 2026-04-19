#!/usr/bin/env bash
set -euo pipefail

readonly RW_WORKSTATION_STEP_IMPLEMENTATION="real"

fail() {
  echo "install-opencode: $1" >&2
  exit 1
}

usage() {
  echo "Usage: $(basename "$0") [--check]" >&2
}

is_installed() {
  if [[ -x "${HOME}/.opencode/bin/opencode" ]]; then
    export PATH="${HOME}/.opencode/bin:${PATH}"
  fi

  command -v opencode >/dev/null 2>&1
}

print_version_if_available() {
  local version_output

  if command -v timeout >/dev/null 2>&1; then
    if ! version_output="$(timeout 5 opencode --version 2>/dev/null || timeout 5 opencode version 2>/dev/null)"; then
      printf 'install-opencode: opencode already installed\n'
      return 0
    fi
  elif ! version_output="$(opencode --version 2>/dev/null || opencode version 2>/dev/null)"; then
    printf 'install-opencode: opencode already installed\n'
    return 0
  fi

  if [[ -n "${version_output}" ]]; then
    printf 'install-opencode: opencode already installed (%s)\n' "${version_output}"
  else
    printf 'install-opencode: opencode already installed\n'
  fi
}

install_opencode() {
  if ! command -v curl >/dev/null 2>&1; then
    fail "required command not found: curl"
  fi

  if ! command -v bash >/dev/null 2>&1; then
    fail "required command not found: bash"
  fi

  printf 'install-opencode: installing OpenCode via official installer\n'
  curl -fsSL https://opencode.ai/install | bash
}

if [[ "${RW_SKIP_OPENCODE_INSTALL:-}" == "1" ]]; then
  printf 'install-opencode: installation skipped by RW_SKIP_OPENCODE_INSTALL=1\n'
  exit 0
fi

case "${1:-}" in
  --check)
    if [[ $# -ne 1 ]]; then
      usage
      exit 2
    fi

    if is_installed; then
      print_version_if_available
      exit 0
    fi

    fail "OpenCode is not installed"
    ;;
  "")
    if [[ $# -ne 0 ]]; then
      usage
      exit 2
    fi
    ;;
  *)
    usage
    exit 2
    ;;
esac

if is_installed; then
  print_version_if_available
  exit 0
fi

install_opencode
