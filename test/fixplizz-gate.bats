#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export PATH="$ROOT/bin:/c/Users/User/AppData/Local/hermes/node:$PATH"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
}

write_os_release() {
  printf 'ID=%s\nVERSION_ID=%s\n' "$1" "$2" >"$BATS_TEST_TMPDIR/os-release"
}

run_gate() {
  env \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release" \
    FIXPLIZZ_TEST_ARCH="$1" \
    bash -c "source '$ROOT/install/helpers/gate.sh'; fixplizz_require_supported_environment"
}

@test "hard gate accepts Ubuntu 26.04 x86_64" {
  write_os_release ubuntu 26.04
  run run_gate x86_64
  [ "$status" -eq 0 ]
}

@test "hard gate rejects Ubuntu 24.04" {
  write_os_release ubuntu 24.04
  run run_gate x86_64
  [ "$status" -eq 3 ]
  [[ "$output" == *"requires Ubuntu 26.04"* ]]
}

@test "hard gate rejects Ubuntu 26.10" {
  write_os_release ubuntu 26.10
  run run_gate x86_64
  [ "$status" -eq 3 ]
  [[ "$output" == *"Detected version: 26.10"* ]]
}

@test "hard gate rejects Debian" {
  write_os_release debian 13
  run run_gate x86_64
  [ "$status" -eq 3 ]
  [[ "$output" == *"supports Ubuntu only"* ]]
}

@test "hard gate rejects ARM64" {
  write_os_release ubuntu 26.04
  run run_gate aarch64
  [ "$status" -eq 3 ]
  [[ "$output" == *"supports x86_64 only"* ]]
}

@test "test override variables are ignored without FIXPLIZZ_TEST_MODE" {
  write_os_release debian 13
  run env \
    FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release" \
    FIXPLIZZ_TEST_ARCH=x86_64 \
    bash -c "source '$ROOT/install/helpers/detection.sh'; fixplizz_detect_version"
  [ "$status" -eq 0 ]
  [ "$output" != "13" ]
}

@test "doctor warns when GNOME is absent" {
  write_os_release ubuntu 26.04
  run env \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release" \
    FIXPLIZZ_TEST_ARCH=x86_64 \
    FIXPLIZZ_TEST_DESKTOP=unknown \
    FIXPLIZZ_TEST_SESSION=wayland \
    "$ROOT/bin/fixplizz" doctor
  [[ "$output" == *"[WARN] desktop"* ]]
}

@test "doctor warns when session is X11" {
  write_os_release ubuntu 26.04
  run env \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release" \
    FIXPLIZZ_TEST_ARCH=x86_64 \
    FIXPLIZZ_TEST_DESKTOP=ubuntu:GNOME \
    FIXPLIZZ_TEST_SESSION=x11 \
    "$ROOT/bin/fixplizz" doctor
  [[ "$output" == *"[WARN] session"* ]]
}

@test "install path creates Fixplizz user runtime directories only" {
  write_os_release ubuntu 26.04
  run env \
    HOME="$HOME" \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release" \
    FIXPLIZZ_TEST_ARCH=x86_64 \
    bash "$ROOT/install.sh"
  [ "$status" -eq 0 ]
  [ -d "$HOME/.local/share/fixplizz" ]
  [ -d "$HOME/.local/state/fixplizz" ]
  [ ! -d "$HOME/.local/share/omakub" ]
}

@test "install hard gate fails before user runtime changes" {
  write_os_release debian 13
  run env \
    HOME="$HOME" \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release" \
    FIXPLIZZ_TEST_ARCH=x86_64 \
    bash "$ROOT/install.sh"
  [ "$status" -eq 3 ]
  [ ! -e "$HOME/.local/share/fixplizz" ]
  [ ! -e "$HOME/.local/state/fixplizz" ]
  [ ! -e "$HOME/.config/fixplizz" ]
}

@test "boot hard gate logs a large actionable failure before system changes" {
  write_os_release debian 13
  run env \
    HOME="$HOME" \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release" \
    FIXPLIZZ_TEST_ARCH=x86_64 \
    bash "$ROOT/boot.sh"
  [ "$status" -eq 3 ]
  [ ! -e "$HOME/.local/bin/fixplizz" ]
  [ ! -e "$HOME/.local/share/fixplizz" ]
  [ -d "$HOME/.local/state/fixplizz" ]
  bootstrap_log="$(find "$HOME/.local/state/fixplizz" -maxdepth 1 -name 'bootstrap-*.log' -print -quit)"
  [ -s "$bootstrap_log" ]
  [[ "$output" == *"FIXPLIZZ BOOTSTRAP FAILED"* ]]
  [[ "$output" == *"Stage: bootstrap"* ]]
  [[ "$output" == *"Exit code: 3"* ]]
  [[ "$output" == *"Full log: $bootstrap_log"* ]]
  [[ "$output" == *"Continue: bash -c 'set -o pipefail; curl -fsSL --retry 3 https://raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/v0.1.0-rc5/boot.sh | bash'"* ]]
  grep -Fq 'Fixplizz Workstation supports Ubuntu only' "$bootstrap_log"
}

@test "default PR1 path does not call destructive inherited policies" {
  ! grep -Eq 'remove-snap|apt[ -]upgrade|tlp|gdm|plymouth|omakasui' "$ROOT/boot.sh" "$ROOT/install.sh"
}
