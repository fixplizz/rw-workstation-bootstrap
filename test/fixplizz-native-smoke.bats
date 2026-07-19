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

prepare_release_fixture() {
  export EXPECTED_COMMIT=2222222222222222222222222222222222222222
  export CURL_LOG="$BATS_TEST_TMPDIR/curl.log"
  export EXEC_LOG="$BATS_TEST_TMPDIR/executed.log"
  export BOOT_FIXTURE="$BATS_TEST_TMPDIR/boot.sh"
  export MANIFEST_FIXTURE="$BATS_TEST_TMPDIR/release-artifacts.rc"
  fake_bin="$BATS_TEST_TMPDIR/fake-bin"
  mkdir -p "$fake_bin"
  cat >"$BOOT_FIXTURE" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$EXEC_LOG"
SH
  printf 'FIXPLIZZ_BOOT_SHA256=%s\n' "$(sha256sum "$BOOT_FIXTURE" | awk '{print $1}')" >"$MANIFEST_FIXTURE"
  cat >"$fake_bin/git" <<'SH'
#!/usr/bin/env bash
printf '%s\t%s\n' 1111111111111111111111111111111111111111 refs/tags/v0.1.0-rc3
printf '%s\t%s\n' 2222222222222222222222222222222222222222 'refs/tags/v0.1.0-rc3^{}'
SH
  cat >"$fake_bin/curl" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CURL_LOG"
url=''
output=''
while (($#)); do
  case "$1" in
    -o|--output) shift; output="$1" ;;
    https://*) url="$1" ;;
  esac
  shift
done
[[ -n $url && -n $output ]] || exit 90
case "$url" in
  */config/release-artifacts.rc) cp "$MANIFEST_FIXTURE" "$output" ;;
  */boot.sh) cp "$BOOT_FIXTURE" "$output" ;;
  *) exit 91 ;;
esac
SH
  chmod +x "$fake_bin/git" "$fake_bin/curl" "$BOOT_FIXTURE"
  export PATH="$fake_bin:$PATH"
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
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 "$SMOKE" --execute
  [ "$status" -eq 2 ]
  [[ "$output" == *"FIXPLIZZ_NATIVE_SMOKE_ACK"* ]]
  [ ! -e "$FIXPLIZZ_SMOKE_STATE_HOME/phase-state.json" ]
}

@test "native smoke rejects unsupported OS" {
  printf 'ID=debian\nVERSION_ID=13\n' >"$FIXPLIZZ_SMOKE_OS_RELEASE"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 "$SMOKE"
  [ "$status" -eq 3 ]
  [[ "$output" == *"Ubuntu 26.04"* ]]
}

@test "native smoke rejects unsupported architecture" {
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 FIXPLIZZ_SMOKE_ARCH=aarch64 "$SMOKE"
  [ "$status" -eq 3 ]
  [[ "$output" == *"x86_64"* ]]
}

@test "primary install uses immutable published boot and installed CLI" {
  grep -Fq 'raw.githubusercontent.com/$REPOSITORY_SLUG/$RC_COMMIT_SHA/boot.sh' "$SMOKE"
  grep -Fq 'bash -s -- --profile mvp --noninteractive <"$VERIFIED_BOOT_FILE"' "$SMOKE"
  grep -Fq 'INSTALLED_CLI="$HOME/.local/bin/fixplizz"' "$SMOKE"
  ! grep -Fq 'curl -fsSL --retry 3 "$boot_url" | bash' "$SMOKE"
  ! grep -Fq '"$ROOT/bin/fixplizz" install --profile mvp --noninteractive' "$SMOKE"
}

@test "tag resolves first and the single commit-addressed boot download is executed" {
  prepare_release_fixture
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 bash -c "source '$SMOKE'; smoke_fetch_release_artifact; smoke_execute_verified_boot"
  [ "$status" -eq 0 ]
  [ "$(wc -l <"$CURL_LOG" | tr -d ' ')" -eq 2 ]
  [ "$(grep -Fc "/$EXPECTED_COMMIT/boot.sh" "$CURL_LOG")" -eq 1 ]
  [ "$(grep -Fc "/$EXPECTED_COMMIT/config/release-artifacts.rc" "$CURL_LOG")" -eq 1 ]
  [ "$(cat "$EXEC_LOG")" = "--profile mvp --noninteractive" ]
  [ "$(find "$FIXPLIZZ_SMOKE_STATE_HOME" -name "boot-v0.1.0-rc3-$EXPECTED_COMMIT.sh" | wc -l | tr -d ' ')" -eq 1 ]
}

@test "checksum mismatch prevents verified boot execution" {
  prepare_release_fixture
  printf 'FIXPLIZZ_BOOT_SHA256=%064d\n' 0 >"$MANIFEST_FIXTURE"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 bash -c "source '$SMOKE'; smoke_fetch_release_artifact; smoke_execute_verified_boot"
  [ "$status" -eq 6 ]
  [ ! -e "$EXEC_LOG" ]
  grep -Fq "/$EXPECTED_COMMIT/boot.sh" "$CURL_LOG"
}

@test "invalid resolved commit prevents release downloads and execution" {
  prepare_release_fixture
  cat >"$BATS_TEST_TMPDIR/fake-bin/git" <<'SH'
#!/usr/bin/env bash
printf '%s\t%s\n' invalid 'refs/tags/v0.1.0-rc3^{}'
SH
  chmod +x "$BATS_TEST_TMPDIR/fake-bin/git"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 bash -c "source '$SMOKE'; smoke_fetch_release_artifact; smoke_execute_verified_boot"
  [ "$status" -eq 6 ]
  [ ! -e "$CURL_LOG" ]
  [ ! -e "$EXEC_LOG" ]
}

@test "release artifact verification rejects a lightweight tag" {
  mkdir -p "$FIXPLIZZ_SMOKE_STATE_HOME"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 bash -c "source '$SMOKE'; git() { printf '%040d refs/tags/v0.1.0-rc3\\n' 0; }; curl() { return 99; }; smoke_fetch_release_artifact"
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
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 bash -c "source '$SMOKE'; smoke_run_cli_checks first"
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
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 "$SMOKE" --verify-after-reboot
  [ "$status" -eq 4 ]
  [[ "$output" == *"phase state"* ]]
}

@test "after-reboot phase rejects a different requested release ref" {
  mkdir -p "$FIXPLIZZ_SMOKE_STATE_HOME"
  printf '%s\n' '{"phase":"pending-after-reboot","requested_rc_tag":"v0.1.0-rc2","resolved_commit_sha":"2222222222222222222222222222222222222222","expected_boot_sha256":"aaa","actual_boot_sha256":"aaa","executed_verified_artifact":true,"first_run_id":"one","second_run_id":"two","resume_source_run_id":"three","resume_result_run_id":"four","logout_required":"yes","reboot_required":"yes"}' >"$FIXPLIZZ_SMOKE_STATE_HOME/phase-state.json"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 bash -c "source '$SMOKE'; smoke_load_phase_state"
  [ "$status" -eq 4 ]
  [[ "$output" == *"does not match"* ]]
}

@test "phase state records the executed checksum-verified artifact" {
  mkdir -p "$FIXPLIZZ_SMOKE_STATE_HOME"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 RC_COMMIT_SHA=2222222222222222222222222222222222222222 MANIFEST_URL=https://raw.example/manifest BOOT_ARTIFACT_URL=https://raw.example/boot EXPECTED_BOOT_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ACTUAL_BOOT_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa VERIFIED_BOOT_FILE=verified-boot.sh EXECUTED_VERIFIED_ARTIFACT=true bash -c "source '$SMOKE'; smoke_write_phase_state"
  [ "$status" -eq 0 ]
  run python - "$FIXPLIZZ_SMOKE_STATE_HOME/phase-state.json" <<'PY'
import json, pathlib, sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert data["requested_rc_tag"] == "v0.1.0-rc3"
assert data["resolved_commit_sha"] == "2222222222222222222222222222222222222222"
assert data["manifest_url"] == "https://raw.example/manifest"
assert data["boot_artifact_url"] == "https://raw.example/boot"
assert data["expected_boot_sha256"] == data["actual_boot_sha256"]
assert data["verified_file_path"] == "verified-boot.sh"
assert data["executed_verified_artifact"] is True
PY
  [ "$status" -eq 0 ]
}

@test "report cannot declare PASS without verified artifact execution" {
  report="$BATS_TEST_TMPDIR/unverified-report.md"
  run env FIXPLIZZ_SMOKE_REF=v0.1.0-rc3 EXECUTED_VERIFIED_ARTIFACT=false bash -c "source '$SMOKE'; smoke_write_report '$report' PASS"
  [ "$status" -ne 0 ]
  if [ -e "$report" ]; then
    ! grep -Fq 'Overall: PASS' "$report"
  fi
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
