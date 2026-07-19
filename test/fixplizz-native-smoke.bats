#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export SMOKE="$ROOT/scripts/smoke/native-ubuntu-26.04.sh"
  export HOME="$BATS_TEST_TMPDIR/home"
  export FIXPLIZZ_SMOKE_STATE_HOME="$BATS_TEST_TMPDIR/smoke-state"
  export FIXPLIZZ_SMOKE_TEST_MODE=1
  export FIXPLIZZ_SMOKE_PYTHON=python
  export FIXPLIZZ_SMOKE_ARCH=x86_64
  export FIXPLIZZ_SMOKE_DESKTOP=ubuntu:GNOME
  export FIXPLIZZ_SMOKE_SESSION=wayland
  mkdir -p "$HOME"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' >"$BATS_TEST_TMPDIR/os-release"
  export FIXPLIZZ_SMOKE_OS_RELEASE="$BATS_TEST_TMPDIR/os-release"
}

@test "native smoke requires an explicit release ref" {
  run "$SMOKE"
  [ "$status" -eq 2 ]
  [[ "$output" == *"FIXPLIZZ_SMOKE_REF"* ]]
}

@test "native smoke rejects mutable main and latest refs" {
  for ref in main latest refs/heads/main; do
    run env FIXPLIZZ_SMOKE_REF="$ref" "$SMOKE"
    [ "$status" -eq 2 ]
    [[ "$output" == *"immutable"* ]]
  done
}

@test "execute requires disposable host acknowledgment before installation" {
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 "$SMOKE" --execute
  [ "$status" -eq 2 ]
  [[ "$output" == *"FIXPLIZZ_NATIVE_SMOKE_ACK"* ]]
  [ ! -e "$FIXPLIZZ_SMOKE_STATE_HOME/phase-state.json" ]
}

@test "native smoke rejects unsupported OS" {
  printf 'ID=debian\nVERSION_ID=13\n' >"$FIXPLIZZ_SMOKE_OS_RELEASE"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 "$SMOKE"
  [ "$status" -eq 3 ]
  [[ "$output" == *"Ubuntu 26.04"* ]]
}

@test "native smoke rejects unsupported architecture" {
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 FIXPLIZZ_SMOKE_ARCH=aarch64 "$SMOKE"
  [ "$status" -eq 3 ]
  [[ "$output" == *"x86_64"* ]]
}

@test "primary install uses immutable published boot and installed CLI" {
  grep -Fq 'raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/${FIXPLIZZ_SMOKE_REF}/boot.sh' "$SMOKE"
  grep -Fq '| bash -s -- --profile mvp --noninteractive' "$SMOKE"
  grep -Fq 'INSTALLED_CLI="$HOME/.local/bin/fixplizz"' "$SMOKE"
  ! grep -Fq '"$ROOT/bin/fixplizz" install --profile mvp --noninteractive' "$SMOKE"
}

@test "release artifact verification rejects a lightweight tag" {
  mkdir -p "$FIXPLIZZ_SMOKE_STATE_HOME"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 bash -c "source '$SMOKE'; git() { printf '%040d refs/tags/v0.1.0-rc2\\n' 0; }; curl() { return 99; }; smoke_fetch_release_artifact"
  [ "$status" -eq 6 ]
  [[ "$output" == *"annotated"* ]]
}

@test "installed CLI version must match the requested release ref" {
  mkdir -p "$HOME/.local/bin" "$FIXPLIZZ_SMOKE_STATE_HOME"
  cat >"$HOME/.local/bin/fixplizz" <<'SH'
#!/bin/sh
case "$*" in
  version) echo '0.1.0-rc1' ;;
  *--json) echo '{}' ;;
  *) echo ok ;;
esac
SH
  chmod +x "$HOME/.local/bin/fixplizz"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 bash -c "source '$SMOKE'; smoke_run_cli_checks first"
  [ "$status" -eq 7 ]
  [[ "$output" == *"does not match"* ]]
}

@test "smoke invokes the second run and isolated resume fixture" {
  grep -Fq '"$INSTALLED_CLI" install --profile mvp --noninteractive' "$SMOKE"
  grep -Fq 'smoke_run_resume_fixture' "$SMOKE"
  grep -Fq 'FIXPLIZZ_TEST_FAIL_MODULE=' "$SMOKE"
  grep -Fq -- '--resume --noninteractive' "$SMOKE"
}

@test "after-reboot phase requires saved phase state" {
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 "$SMOKE" --verify-after-reboot
  [ "$status" -eq 4 ]
  [[ "$output" == *"phase state"* ]]
}

@test "after-reboot phase rejects a different requested release ref" {
  mkdir -p "$FIXPLIZZ_SMOKE_STATE_HOME"
  printf '%s\n' '{"phase":"pending-after-reboot","rc_tag":"v0.1.0-rc1","rc_commit_sha":"abc","boot_sha256":"def","first_run_id":"one","second_run_id":"two","resume_source_run_id":"three","resume_result_run_id":"four","logout_required":"yes","reboot_required":"yes"}' >"$FIXPLIZZ_SMOKE_STATE_HOME/phase-state.json"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 bash -c "source '$SMOKE'; smoke_load_phase_state"
  [ "$status" -eq 4 ]
  [[ "$output" == *"does not match"* ]]
}

@test "report renderer never copies environment secrets" {
  report="$BATS_TEST_TMPDIR/report.md"
  run env TOP_SECRET_VALUE='do-not-copy-this' bash -c "source '$SMOKE'; smoke_write_report '$report' draft"
  [ "$status" -eq 0 ]
  [ -s "$report" ]
  grep -Fq '## Automated acceptance' "$report"
  grep -Fq '~/.local/state/fixplizz/runs/pending/install.log' "$report"
  grep -Fq 'Idempotency snapshot comparison:' "$report"
  grep -Fq '~/.local/state/fixplizz/native-smoke/first-status.json' "$report"
  grep -Fq '~/.local/state/fixplizz/native-smoke/second-modules.txt' "$report"
  ! grep -Fq 'do-not-copy-this' "$report"
  ! grep -Eqi '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|access[_-]?token[[:space:]]*=|password[[:space:]]*=)' "$report"
}

@test "smoke harness cannot create move or delete release tags" {
  ! grep -Eq 'git[[:space:]]+(tag|push[^#]*refs/tags)|tag[[:space:]]+-d' "$SMOKE"
}
