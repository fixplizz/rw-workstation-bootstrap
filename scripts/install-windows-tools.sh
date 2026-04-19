#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "install-windows-tools: $1" >&2
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "${script_dir}/.." && pwd -P)"
powershell_script="${repo_root}/bootstrap/windows/install-windows-tools.ps1"

powershell_bin="${POWERSHELL_EXE:-}"
if [[ -z "${powershell_bin}" ]]; then
  for candidate in \
    "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" \
    "/mnt/c/Program Files/PowerShell/7/pwsh.exe"
  do
    if [[ -x "${candidate}" ]]; then
      powershell_bin="${candidate}"
      break
    fi
  done
fi

if [[ -z "${powershell_bin}" ]]; then
  fail "PowerShell executable was not found under /mnt/c/Windows"
fi

if [[ ! -f "${powershell_script}" ]]; then
  fail "missing PowerShell installer: ${powershell_script}"
fi

"${powershell_bin}" -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "${powershell_script}")"
