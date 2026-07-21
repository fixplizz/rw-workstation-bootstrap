#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

export PATH="$ROOT/bin:/c/Users/User/AppData/Local/hermes/node:$PATH"

if command -v cygpath >/dev/null 2>&1 && [[ -n ${LOCALAPPDATA:-} ]]; then
  winget_packages="$(cygpath "$LOCALAPPDATA/Microsoft/WinGet/Packages")"
  if [[ -d "$winget_packages" ]]; then
    for package_dir in "$winget_packages"/*; do
      [[ -d "$package_dir" ]] && export PATH="$package_dir:$PATH"
    done
  fi
fi

PR1_SHELL_FILES=(
  boot.sh
  install.sh
  bin/fixplizz
  bin/fixplizz-commands
  bin/fixplizz-doctor
  bin/fixplizz-help
  bin/fixplizz-resume
  bin/fixplizz-runtime
  bin/fixplizz-status
  bin/fixplizz-version
  install/helpers/fixplizz-env.sh
  install/helpers/detection.sh
  install/helpers/gate.sh
  test/run.sh
)

MVP_SHELL_FILES=(
  bin/fixplizz-install
  bin/fixplizz-module-list
  install/helpers/artifacts.sh
  install/helpers/checksum.sh
  install/helpers/files.sh
  install/helpers/flatpak.sh
  install/helpers/module.sh
  install/helpers/packages.sh
  install/helpers/profile.sh
  install/helpers/repositories.sh
  install/helpers/runner.sh
  install/helpers/state.sh
  modules/ai-base.sh
  modules/core.sh
  modules/daily-base.sh
  modules/desktop.sh
  modules/developer.sh
  modules/devops-base.sh
  modules/remote-base.sh
  modules/terminal.sh
  scripts/ci/policy-scan.sh
  scripts/ci/secrets-boundary.sh
  scripts/smoke/native-ubuntu-26.04.sh
)

SHELL_FILES=("${PR1_SHELL_FILES[@]}" "${MVP_SHELL_FILES[@]}")

PR1_TEXT_FILES=(
  "${PR1_SHELL_FILES[@]}"
  test/fixplizz-cli.bats
  test/fixplizz-gate.bats
  .github/workflows/ci.yml
  .gitattributes
  README.md
  docs/architecture.md
  docs/development.md
  docs/legacy-inventory.md
  docs/upstream.md
  NOTICE.md
  THIRD_PARTY_NOTICES.md
)

MVP_TEXT_FILES=(
  "${MVP_SHELL_FILES[@]}"
  profiles/mvp
  config/sources.rc
  config/release-artifacts.rc
  test/fixplizz-mvp.bats
  test/fixplizz-boot.bats
  test/fixplizz-json.bats
  test/fixplizz-native-smoke.bats
  test/fixplizz-policy.bats
  test/fixplizz-sources.bats
  docs/native-smoke-test.md
  docs/native-smoke-report-template.md
)

TEXT_FILES=("${PR1_TEXT_FILES[@]}" "${MVP_TEXT_FILES[@]}")

printf '== bash -n ==\n'
for file in "${SHELL_FILES[@]}"; do
  bash -n "$file"
done

printf '== line endings and bom ==\n'
for file in "${TEXT_FILES[@]}"; do
  if grep -q $'\r' "$file"; then
    printf 'CRLF detected: %s\n' "$file" >&2
    exit 1
  fi
  python - "$file" <<'PY'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
data = path.read_bytes()
if data.startswith(b"\xef\xbb\xbf"):
    raise SystemExit(f"BOM detected: {path}")
PY
done

printf '== executable bits ==\n'
for file in \
  boot.sh \
  install.sh \
  bin/fixplizz \
  bin/fixplizz-commands \
  bin/fixplizz-doctor \
  bin/fixplizz-help \
  bin/fixplizz-resume \
  bin/fixplizz-runtime \
  bin/fixplizz-status \
  bin/fixplizz-version \
  install/helpers/fixplizz-env.sh \
  install/helpers/detection.sh \
  install/helpers/gate.sh \
  bin/fixplizz-install \
  bin/fixplizz-module-list \
  install/helpers/artifacts.sh \
  install/helpers/checksum.sh \
  install/helpers/files.sh \
  install/helpers/flatpak.sh \
  install/helpers/module.sh \
  install/helpers/packages.sh \
  install/helpers/profile.sh \
  install/helpers/repositories.sh \
  install/helpers/runner.sh \
  install/helpers/state.sh \
  modules/ai-base.sh \
  modules/core.sh \
  modules/daily-base.sh \
  modules/desktop.sh \
  modules/developer.sh \
  modules/devops-base.sh \
  modules/remote-base.sh \
  modules/terminal.sh \
  scripts/ci/policy-scan.sh \
  scripts/ci/secrets-boundary.sh \
  scripts/smoke/native-ubuntu-26.04.sh \
  test/run.sh; do
  mode="$(git ls-files -s "$file" | awk '{print $1}')"
  if [[ "$mode" != "100755" ]]; then
    printf 'Expected executable bit in Git index for %s, got %s\n' "$file" "$mode" >&2
    exit 1
  fi
done

if command -v shellcheck >/dev/null 2>&1; then
  printf '== shellcheck ==\n'
  shellcheck "${SHELL_FILES[@]}"
else
  printf '== shellcheck skipped: not installed ==\n'
fi

if command -v shfmt >/dev/null 2>&1; then
  printf '== shfmt --check ==\n'
  shfmt -d -i 2 -ci "${SHELL_FILES[@]}"
else
  printf '== shfmt skipped: not installed ==\n'
fi

if [[ ${FIXPLIZZ_LINT_ONLY:-0} == 1 ]]; then
  printf 'Lint validation complete.\n'
  exit 0
fi

printf '== bats ==\n'
bats test/*.bats

printf '== metadata ==\n'
bin/fixplizz commands --check

printf '== json validation ==\n'
bin/fixplizz commands --json | python -m json.tool >/dev/null
tmp_os_release="$(mktemp)"
trap 'rm -f "$tmp_os_release"' EXIT
printf 'ID=ubuntu\nVERSION_ID=26.04\n' >"$tmp_os_release"
FIXPLIZZ_TEST_MODE=1 \
  FIXPLIZZ_OS_RELEASE_FILE="$tmp_os_release" \
  FIXPLIZZ_TEST_ARCH=x86_64 \
  FIXPLIZZ_TEST_DESKTOP=ubuntu:GNOME \
  FIXPLIZZ_TEST_SESSION=wayland \
  bin/fixplizz doctor --json | python -m json.tool >/dev/null
bin/fixplizz status --json | python -m json.tool >/dev/null

printf 'Validation complete.\n'
