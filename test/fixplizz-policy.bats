#!/usr/bin/env bats

setup() { export ROOT="$BATS_TEST_DIRNAME/.."; }

@test "CI defines all mandatory RC jobs on Ubuntu 26.04" {
  for job in lint unit integration-headless secrets-boundary; do
    grep -Eq "^  ${job}:" "$ROOT/.github/workflows/ci.yml"
  done
  [ "$(grep -c 'runs-on: ubuntu-26.04' "$ROOT/.github/workflows/ci.yml")" -eq 4 ]
}

@test "CI uses the repository lint contract and pinned shfmt" {
  grep -Fq 'mvdan.cc/sh/v3/cmd/shfmt@v3.13.1' "$ROOT/.github/workflows/ci.yml"
  grep -Fq 'FIXPLIZZ_LINT_ONLY=1 bash test/run.sh' "$ROOT/.github/workflows/ci.yml"
  ! grep -Fq 'install/helpers/*.sh' "$ROOT/.github/workflows/ci.yml"
}

@test "CI validates the published Pages bootstrap" {
  grep -Fq 'cmp --silent boot.sh docs/install' "$ROOT/.github/workflows/ci.yml"
  grep -Fq 'bash -n docs/install' "$ROOT/.github/workflows/ci.yml"
  grep -Fq 'shellcheck docs/install' "$ROOT/.github/workflows/ci.yml"
}

@test "policy and native smoke scripts are executable" {
  for script in scripts/ci/policy-scan.sh scripts/ci/secrets-boundary.sh scripts/smoke/native-ubuntu-26.04.sh; do
    [ -x "$ROOT/$script" ]
  done
}

@test "README leads with RC install and blocks stable release" {
  first_command="$(awk '/^```bash$/ {getline; print; exit}' "$ROOT/README.md")"
  [ "$first_command" = "bash -c 'set -o pipefail; curl -fsSL --retry 3 https://fixplizz.github.io/rw-workstation-bootstrap/install | bash'" ]
  grep -Fq "https://raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/v0.1.0-rc4/boot.sh" "$ROOT/README.md"
  grep -Fq 'v0.1.0 remains blocked' "$ROOT/README.md"
  [ -f "$ROOT/docs/native-smoke-test.md" ]
  [ -f "$ROOT/docs/native-smoke-report-template.md" ]
}

@test "Pages install is the complete RC4 bootstrap without HTML" {
  [ -f "$ROOT/docs/.nojekyll" ]
  [ -f "$ROOT/docs/index.html" ]
  cmp --silent "$ROOT/boot.sh" "$ROOT/docs/install"
  [ "$(head -n 1 "$ROOT/docs/install")" = '#!/usr/bin/env bash' ]
  ! grep -Eiq '<(!doctype|html|head|body|script)([[:space:]>])' "$ROOT/docs/install"
  grep -Fq "v$(tr -d '[:space:]' <"$ROOT/version")" "$ROOT/docs/install"
  grep -Fq 'v0.1.0-rc4' "$ROOT/docs/install"
  bash -n "$ROOT/docs/install"
}

@test "Pages install passes standalone ShellCheck" {
  command -v shellcheck >/dev/null || skip 'shellcheck is not installed'
  run shellcheck "$ROOT/docs/install"
  [ "$status" -eq 0 ]
}

@test "Pages landing page is static and documents the supported pilot" {
  grep -Fq 'Fixplizz Workstation' "$ROOT/docs/index.html"
  grep -Fq 'Ubuntu 26.04 Desktop amd64' "$ROOT/docs/index.html"
  grep -Fq 'release candidate' "$ROOT/docs/index.html"
  grep -Fq 'fixplizz resume' "$ROOT/docs/index.html"
  grep -Fq 'https://github.com/fixplizz/rw-workstation-bootstrap' "$ROOT/docs/index.html"
  ! grep -Eiq '<script|analytics|cookie|<form' "$ROOT/docs/index.html"
}

@test "README one-command wrapper returns non-zero when download fails" {
  first_command="$(awk '/^```bash$/ {getline; print; exit}' "$ROOT/README.md")"
  fake_bin="$BATS_TEST_TMPDIR/fake-bin"
  mkdir -p "$fake_bin"
  cat >"$fake_bin/curl" <<'SH'
#!/bin/sh
exit 35
SH
  chmod +x "$fake_bin/curl"

  run env PATH="$fake_bin:$PATH" bash -c "$first_command"
  [ "$status" -eq 35 ]
}

@test "RC4 entrypoints and boot checksum manifest are consistent" {
  grep -Fq 'v0.1.0-rc4' "$ROOT/boot.sh"
  grep -Fq 'v0.1.0-rc4' "$ROOT/install/helpers/fixplizz-env.sh"
  [ "$(tr -d '[:space:]' <"$ROOT/version")" = "0.1.0-rc4" ]
  source "$ROOT/config/release-artifacts.rc"
  [ "$FIXPLIZZ_BOOT_SHA256" = "$(sha256sum "$ROOT/boot.sh" | awk '{print $1}')" ]
}
