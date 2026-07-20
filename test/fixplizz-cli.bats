#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export CLI="$ROOT/bin/fixplizz"
  export PATH="$ROOT/bin:/c/Users/User/AppData/Local/hermes/node:$PATH"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
}

json_query() {
  python -c 'import json,sys; data=json.load(sys.stdin); exec(sys.argv[1])' "$1"
}

@test "fixplizz help renders public help" {
  run "$CLI" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Fixplizz Workstation command center"* ]]
  [[ "$output" == *"fixplizz doctor"* ]]
  [[ "$output" != *"Omabuntu command center"* ]]
}

@test "fixplizz version renders version" {
  run "$CLI" version
  [ "$status" -eq 0 ]
  [ "$output" = "Fixplizz Workstation 0.1.0-rc5" ]
}

@test "fixplizz commands lists PR1 commands" {
  run "$CLI" commands
  [ "$status" -eq 0 ]
  [[ "$output" == *"fixplizz doctor"* ]]
  [[ "$output" == *"fixplizz status"* ]]
  [[ "$output" == *"fixplizz resume"* ]]
  [[ "$output" != *"omakub"* ]]
}

@test "fixplizz commands --json emits valid JSON only" {
  run "$CLI" commands --json
  [ "$status" -eq 0 ]
  [[ "$output" == \{* ]]
  printf '%s' "$output" | json_query 'assert data["ok"] is True; assert any(c["route"] == "fixplizz doctor" for c in data["commands"])'
}

@test "fixplizz commands --check validates metadata" {
  run "$CLI" commands --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"Command metadata check passed"* ]]
}

@test "unknown command returns exit code 2" {
  run "$CLI" does-not-exist
  [ "$status" -eq 2 ]
  [[ "$output" == *"Unknown Fixplizz command"* ]]
}

@test "doctor --json emits valid JSON without progress text" {
  os_release="$BATS_TEST_TMPDIR/os-release"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' >"$os_release"

  run env \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_OS_RELEASE_FILE="$os_release" \
    FIXPLIZZ_TEST_ARCH=x86_64 \
    FIXPLIZZ_TEST_DESKTOP=ubuntu:GNOME \
    FIXPLIZZ_TEST_SESSION=wayland \
    "$CLI" doctor --json

  [ "$status" -eq 0 ]
  [[ "$output" == \{* ]]
  printf '%s' "$output" | json_query 'assert data["command"] == "doctor"; assert any(c["name"] == "version" and c["status"] == "OK" for c in data["checks"])'
}

@test "doctor --json failure has ok false, arrays, no ansi, and non-zero exit" {
  os_release="$BATS_TEST_TMPDIR/os-release"
  stdout_file="$BATS_TEST_TMPDIR/stdout.json"
  stderr_file="$BATS_TEST_TMPDIR/stderr.txt"
  printf 'ID=debian\nVERSION_ID=13\n' >"$os_release"

  set +e
  env \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_OS_RELEASE_FILE="$os_release" \
    FIXPLIZZ_TEST_ARCH=aarch64 \
    FIXPLIZZ_TEST_DESKTOP='Quoted "Desktop"' \
    FIXPLIZZ_TEST_SESSION=x11 \
    "$CLI" doctor --json >"$stdout_file" 2>"$stderr_file"
  status_code=$?
  set -e

  [ "$status_code" -eq 1 ]
  [ ! -s "$stderr_file" ]
  ! grep -q $'\033' "$stdout_file"
  python -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["ok"] is False; assert data["command"] == "doctor"; assert isinstance(data["checks"], list); assert isinstance(data["warnings"], list); assert isinstance(data["errors"], list); assert data["errors"]' "$stdout_file"
}

@test "status --json reports release candidate state" {
  run "$CLI" status --json
  [ "$status" -eq 0 ]
  printf '%s' "$output" | json_query 'assert data["status"]["installation_state"] == "not-installed"; assert data["status"]["release_stage"] == "release-candidate"; assert data["command"] == "status"'
}

@test "runtime list exposes selectable development runtimes" {
  run "$CLI" runtime list
  [ "$status" -eq 0 ]
  [[ "$output" == *"bun"* ]]
  [[ "$output" == *"deno"* ]]
  [[ "$output" == *"java"* ]]
  [[ "$output" == *"dotnet"* ]]
  [[ "$output" == *"ruby"* ]]
  [[ "$output" == *"php"* ]]
  [[ "$output" == *"elixir"* ]]
  [[ "$output" == *"zig"* ]]
}

@test "runtime install delegates only selected runtimes to mise" {
  fake_bin="$BATS_TEST_TMPDIR/fake-bin"
  mise_log="$BATS_TEST_TMPDIR/mise.log"
  mkdir -p "$fake_bin"
  cat >"$fake_bin/mise" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >>"$MISE_LOG"
SH
  chmod +x "$fake_bin/mise"

  run env PATH="$fake_bin:$PATH" MISE_LOG="$mise_log" "$CLI" runtime install bun java zig
  [ "$status" -eq 0 ]
  grep -Fxq 'use --global bun@latest' "$mise_log"
  grep -Fxq 'use --global java@temurin-25' "$mise_log"
  grep -Fxq 'use --global zig@latest' "$mise_log"
  [ "$(wc -l <"$mise_log" | tr -d ' ')" -eq 3 ]
}

@test "runtime install includes Erlang when Elixir is selected" {
  fake_bin="$BATS_TEST_TMPDIR/fake-bin"
  mise_log="$BATS_TEST_TMPDIR/mise.log"
  mkdir -p "$fake_bin"
  cat >"$fake_bin/mise" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >>"$MISE_LOG"
SH
  chmod +x "$fake_bin/mise"

  run env PATH="$fake_bin:$PATH" MISE_LOG="$mise_log" "$CLI" runtime install elixir
  [ "$status" -eq 0 ]
  grep -Fxq 'use --global erlang@latest' "$mise_log"
  grep -Fxq 'use --global elixir@latest' "$mise_log"
}

@test "runtime install rejects unknown runtimes before invoking mise" {
  fake_bin="$BATS_TEST_TMPDIR/fake-bin"
  mise_log="$BATS_TEST_TMPDIR/mise.log"
  mkdir -p "$fake_bin"
  cat >"$fake_bin/mise" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >>"$MISE_LOG"
SH
  chmod +x "$fake_bin/mise"

  run env PATH="$fake_bin:$PATH" MISE_LOG="$mise_log" "$CLI" runtime install cobol
  [ "$status" -eq 2 ]
  [[ "$output" == *"Unsupported runtime: cobol"* ]]
  [ ! -e "$mise_log" ]
}
