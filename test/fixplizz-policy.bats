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
  grep -Fq "https://raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/v0.1.0-rc5/boot.sh" "$ROOT/README.md"
  grep -Fq 'Stable v0.1.0 remains blocked until native Ubuntu 26.04 Desktop acceptance passes.' "$ROOT/README.md"
  [ -f "$ROOT/docs/native-smoke-test.md" ]
  [ -f "$ROOT/docs/native-smoke-report-template.md" ]
}

@test "README presents the public project structure and honest badges" {
  grep -Fq '# Fixplizz Workstation' "$ROOT/README.md"
  grep -Fq '> One-command workstation bootstrap for Ubuntu 26.04 LTS' "$ROOT/README.md"
  grep -Fq 'actions/workflows/ci.yml/badge.svg' "$ROOT/README.md"
  grep -Fq 'github/v/release/fixplizz/rw-workstation-bootstrap?include_prereleases' "$ROOT/README.md"
  grep -Fq 'Ubuntu_26.04_LTS' "$ROOT/README.md"
  grep -Fq 'license-MIT' "$ROOT/README.md"
  ! grep -Eiq 'downloads|coverage|stars' "$ROOT/README.md"

  for heading in 'What you get' 'Why Fixplizz' 'Requirements' 'Useful commands' 'State, logs and recovery' 'Safety boundaries' 'Architecture' 'Release status' 'License and attribution'; do
    grep -Fq "## $heading" "$ROOT/README.md"
  done
}

@test "README documents profile, commands, state and safety boundaries" {
  grep -Fq 'core → desktop → terminal → developer → devops-base → ai-base → daily-base → remote-base' "$ROOT/README.md"
  for command in 'fixplizz status' 'fixplizz status --json' 'fixplizz doctor' 'fixplizz doctor --json' 'fixplizz commands' 'fixplizz resume' 'fixplizz install --profile mvp --dry-run'; do
    grep -Fq "$command" "$ROOT/README.md"
  done
  for path in '~/.local/share/fixplizz' '~/.local/state/fixplizz' '~/.config/fixplizz' '~/.cache/fixplizz' '~/.local/bin/fixplizz' 'runs/<run-id>/run.json' 'runs/<run-id>/modules/*.json' 'runs/<run-id>/install.log'; do
    grep -Fq "$path" "$ROOT/README.md"
  done
  for boundary in 'remove or block Snap' 'run a distribution upgrade' 'enable an SSH server' 'weaken AppArmor' 'create credentials' 'sign in to applications' 'fetch a private repository' 'without creating a backup'; do
    grep -Fqi "$boundary" "$ROOT/README.md"
  done
}

@test "README required local documentation links resolve" {
  for path in docs/architecture.md docs/development.md docs/native-smoke-test.md docs/secrets-repository.md docs/upstream.md NOTICE.md THIRD_PARTY_NOTICES.md LICENSE; do
    [ -f "$ROOT/$path" ]
    grep -Fq "($path)" "$ROOT/README.md"
  done
}

@test "Pages install is the complete RC5 bootstrap without HTML" {
  [ -f "$ROOT/docs/.nojekyll" ]
  [ -f "$ROOT/docs/index.html" ]
  cmp --silent "$ROOT/boot.sh" "$ROOT/docs/install"
  [ "$(head -n 1 "$ROOT/docs/install")" = '#!/usr/bin/env bash' ]
  ! grep -Eiq '<(!doctype|html|head|body|script)([[:space:]>])' "$ROOT/docs/install"
  grep -Fq "v$(tr -d '[:space:]' <"$ROOT/version")" "$ROOT/docs/install"
  grep -Fq 'v0.1.0-rc5' "$ROOT/docs/install"
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
  grep -Fq 'Release Candidate' "$ROOT/docs/index.html"
  grep -Fq 'fixplizz resume' "$ROOT/docs/index.html"
  grep -Fq 'https://github.com/fixplizz/rw-workstation-bootstrap' "$ROOT/docs/index.html"
  grep -Fq 'https://github.com/fixplizz/rw-workstation-bootstrap/releases' "$ROOT/docs/index.html"
  grep -Fq 'prefers-color-scheme: dark' "$ROOT/docs/index.html"
  grep -Fq '.hero > * { min-width: 0; }' "$ROOT/docs/index.html"
  grep -Fq 'rel="icon" href="data:image/svg+xml' "$ROOT/docs/index.html"
  grep -Fq 'id="copy-install"' "$ROOT/docs/index.html"
  grep -Fq 'navigator.clipboard.writeText' "$ROOT/docs/index.html"
  ! grep -Eiq '<script[^>]+src=|analytics|cookie|tracker|<form|https://cdn' "$ROOT/docs/index.html"
}

@test "README and Pages publish the same primary installation command" {
  readme_command="$(awk '/^```bash$/ {getline; print; exit}' "$ROOT/README.md")"
  page_command="$(sed -n 's/.*<code id="install-command">\(.*\)<\/code>.*/\1/p' "$ROOT/docs/index.html")"
  [ -n "$page_command" ]
  [ "$page_command" = "$readme_command" ]
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

@test "RC5 entrypoints and boot checksum manifest are consistent" {
  grep -Fq 'v0.1.0-rc5' "$ROOT/boot.sh"
  grep -Fq 'v0.1.0-rc5' "$ROOT/install/helpers/fixplizz-env.sh"
  [ "$(tr -d '[:space:]' <"$ROOT/version")" = "0.1.0-rc5" ]
  source "$ROOT/config/release-artifacts.rc"
  [ "$FIXPLIZZ_BOOT_SHA256" = "$(sha256sum "$ROOT/boot.sh" | awk '{print $1}')" ]
}
