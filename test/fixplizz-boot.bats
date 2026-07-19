#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export HOME="$BATS_TEST_TMPDIR/home"
  export FIXPLIZZ_PATH="$BATS_TEST_TMPDIR/share/fixplizz"
  export FIXPLIZZ_STATE_HOME="$BATS_TEST_TMPDIR/state"
  export FIXPLIZZ_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export FIXPLIZZ_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
  export FIXPLIZZ_BIN_HOME="$BATS_TEST_TMPDIR/bin"
  export FIXPLIZZ_TEST_MODE=1
  export FIXPLIZZ_TEST_ARCH=x86_64
  export FIXPLIZZ_TEST_DESKTOP=ubuntu:GNOME
  export FIXPLIZZ_TEST_SESSION=wayland
  export FIXPLIZZ_BOOT_SOURCE="$ROOT"
  export FIXPLIZZ_REF="$(git -C "$ROOT" rev-parse HEAD)"
  mkdir -p "$HOME"
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' >"$BATS_TEST_TMPDIR/os-release"
  export FIXPLIZZ_OS_RELEASE_FILE="$BATS_TEST_TMPDIR/os-release"
}

@test "standalone public boot works through stdin outside a checkout and forwards install arguments" {
  cp "$ROOT/boot.sh" "$BATS_TEST_TMPDIR/standalone-boot.sh"
  cd "$BATS_TEST_TMPDIR"
  run bash -s -- --noninteractive <"$BATS_TEST_TMPDIR/standalone-boot.sh"
  [ "$status" -eq 0 ]
  if [[ $(uname -s) == MINGW* ]]; then
    [ -f "$FIXPLIZZ_BIN_HOME/fixplizz" ]
    cli="$FIXPLIZZ_PATH/bin/fixplizz"
  else
    [ -L "$FIXPLIZZ_BIN_HOME/fixplizz" ]
    cli="$FIXPLIZZ_BIN_HOME/fixplizz"
  fi
  [ -r "$FIXPLIZZ_STATE_HOME/current-run" ]
  run "$cli" status --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"installation_state":"completed"'* ]]
}
