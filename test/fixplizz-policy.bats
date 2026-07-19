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

@test "policy and native smoke scripts are executable" {
  for script in scripts/ci/policy-scan.sh scripts/ci/secrets-boundary.sh scripts/smoke/native-ubuntu-26.04.sh; do
    [ -x "$ROOT/$script" ]
  done
}

@test "README leads with RC install and blocks stable release" {
  first_command="$(awk '/^```bash$/ {getline; print; exit}' "$ROOT/README.md")"
  [ "$first_command" = "bash -c 'set -o pipefail; curl -fsSL --retry 3 https://raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/v0.1.0-rc4/boot.sh | bash'" ]
  grep -Fq 'v0.1.0 remains blocked' "$ROOT/README.md"
  [ -f "$ROOT/docs/native-smoke-test.md" ]
  [ -f "$ROOT/docs/native-smoke-report-template.md" ]
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
