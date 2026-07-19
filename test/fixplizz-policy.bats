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
  grep -Fq 'v0.1.0-rc1' "$ROOT/README.md"
  grep -Fq 'v0.1.0 remains blocked' "$ROOT/README.md"
  [ -f "$ROOT/docs/native-smoke-test.md" ]
  [ -f "$ROOT/docs/native-smoke-report-template.md" ]
}
