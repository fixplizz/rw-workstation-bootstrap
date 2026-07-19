#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export HOME="$BATS_TEST_TMPDIR/home"
  export FIXPLIZZ_STATE_HOME="$BATS_TEST_TMPDIR/state"
  export FIXPLIZZ_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export FIXPLIZZ_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
  mkdir -p "$HOME"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' >"$BATS_TEST_TMPDIR/os-release"
  export FIXPLIZZ_TEST_MODE=1
  export FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release"
  export FIXPLIZZ_TEST_ARCH=x86_64
  export FIXPLIZZ_TEST_DESKTOP=ubuntu:GNOME
  export FIXPLIZZ_TEST_SESSION=wayland
}

@test "status JSON reports current run and all module states" {
  run "$ROOT/bin/fixplizz" install --profile mvp --noninteractive
  [ "$status" -eq 0 ]
  run "$ROOT/bin/fixplizz" status --json
  [ "$status" -eq 0 ]
  printf '%s' "$output" | python -c 'import json,sys; d=json.load(sys.stdin); s=d["status"]; assert d["ok"] is True; assert s["installation_state"] == "completed"; assert len(s["modules"]) == 8; assert all(m["status"] == "completed" for m in s["modules"])'
}

@test "doctor JSON exposes stable diagnostic categories and statuses" {
  run "$ROOT/bin/fixplizz" doctor --json
  printf '%s' "$output" | python -c 'import json,sys; d=json.load(sys.stdin); names={c["name"] for c in d["checks"]}; required={"os","version","architecture","sudo","dns","disk","path","checkout","state","apt","flatpak","docker","applications","desktop","session","logout","reboot"}; assert required <= names; assert {c["status"] for c in d["checks"]} <= {"OK","WARN","SKIP","FAIL"}'
}
