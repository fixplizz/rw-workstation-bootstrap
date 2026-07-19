#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export HOME="$BATS_TEST_TMPDIR/home with spaces"
  export FIXPLIZZ_STATE_HOME="$BATS_TEST_TMPDIR/state"
  export FIXPLIZZ_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export FIXPLIZZ_BIN_HOME="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$HOME" "$FIXPLIZZ_STATE_HOME" "$FIXPLIZZ_CONFIG_HOME" "$FIXPLIZZ_BIN_HOME"
}

@test "deb822 renderer uses HTTPS and a dedicated Signed-By keyring" {
  run bash -c "source '$ROOT/install/helpers/repositories.sh'; fixplizz_render_deb822 docker https://download.docker.com/linux/ubuntu resolute stable /etc/apt/keyrings/docker.asc"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Types: deb"* ]]
  [[ "$output" == *"URIs: https://download.docker.com/linux/ubuntu"* ]]
  [[ "$output" == *"Suites: resolute"* ]]
  [[ "$output" == *"Signed-By: /etc/apt/keyrings/docker.asc"* ]]
}

@test "deb822 renderer rejects non-HTTPS repositories" {
  run bash -c "source '$ROOT/install/helpers/repositories.sh'; fixplizz_render_deb822 bad http://example.test stable main /etc/apt/keyrings/bad.asc"
  [ "$status" -ne 0 ]
  [[ "$output" != *"No such file"* ]]
  [[ "$output" != *"command not found"* ]]
}

@test "checksum verification accepts exact sha256 and rejects mismatch" {
  artifact="$BATS_TEST_TMPDIR/artifact"
  printf 'fixplizz\n' >"$artifact"
  expected="$(sha256sum "$artifact" | awk '{print $1}')"
  run bash -c "source '$ROOT/install/helpers/checksum.sh'; fixplizz_verify_sha256 '$artifact' '$expected'"
  [ "$status" -eq 0 ]
  run bash -c "source '$ROOT/install/helpers/checksum.sh'; fixplizz_verify_sha256 '$artifact' '0000000000000000000000000000000000000000000000000000000000000000'"
  [ "$status" -ne 0 ]
}

@test "managed symlink backs up a conflicting user file" {
  target="$BATS_TEST_TMPDIR/target"
  link="$FIXPLIZZ_BIN_HOME/tool"
  printf 'target\n' >"$target"
  printf 'user file\n' >"$link"
  run bash -c "source '$ROOT/install/helpers/files.sh'; fixplizz_managed_symlink '$target' '$link'"
  [ "$status" -eq 0 ]
  if [[ $(uname -s) == MINGW* ]]; then
    [ -f "$link" ]
  else
    [ -L "$link" ]
  fi
  backup_count="$(find "$FIXPLIZZ_STATE_HOME/backups" -type f | wc -l | tr -d ' ')"
  [ "$backup_count" -eq 1 ]
}

@test "shell integration adds one marked source line and preserves a backup" {
  rc="$HOME/.bashrc"
  printf 'export EXISTING=1\n' >"$rc"
  run bash -c "source '$ROOT/install/helpers/files.sh'; fixplizz_install_shell_integration '$rc'"
  [ "$status" -eq 0 ]
  run bash -c "source '$ROOT/install/helpers/files.sh'; fixplizz_install_shell_integration '$rc'"
  [ "$status" -eq 0 ]
  [ "$(grep -c 'FIXPLIZZ MANAGED SHELL' "$rc")" -eq 1 ]
  [ -f "$FIXPLIZZ_CONFIG_HOME/shell/init.sh" ]
  [ "$(find "$FIXPLIZZ_STATE_HOME/backups" -type f | wc -l | tr -d ' ')" -eq 1 ]
}

@test "module files expose all four lifecycle phases" {
  for module in core desktop terminal developer devops-base ai-base daily-base remote-base; do
    for phase in plan check apply verify; do
      run env FIXPLIZZ_TEST_MODE=1 "$ROOT/modules/$module.sh" "$phase"
      if [[ $phase == check ]]; then
        continue
      fi
      [ "$status" -eq 0 ]
    done
  done
}

@test "RC source manifest pins HTTPS amd64 artifacts and SHA256 values" {
  [ -f "$ROOT/config/sources.rc" ]
  run bash -c "source '$ROOT/config/sources.rc'; fixplizz_validate_sources"
  [ "$status" -eq 0 ]
  ! grep -Eqi '(^|[/=-])latest([/._-]|$)|http://' "$ROOT/config/sources.rc"
}

@test "artifact installer rejects a checksum mismatch before installation" {
  fixture="$BATS_TEST_TMPDIR/download"
  printf 'not trusted\n' >"$fixture"
  run env FIXPLIZZ_TEST_DOWNLOAD_FILE="$fixture" bash -c "source '$ROOT/install/helpers/artifacts.sh'; fixplizz_install_binary demo https://example.test/demo '0000000000000000000000000000000000000000000000000000000000000000' demo"
  [ "$status" -ne 0 ]
  [ ! -e "$FIXPLIZZ_BIN_HOME/demo" ]
}

@test "artifact installer verifies before copying into user bin" {
  fixture="$BATS_TEST_TMPDIR/download"
  printf '#!/bin/sh\necho demo\n' >"$fixture"
  expected="$(sha256sum "$fixture" | awk '{print $1}')"
  run env FIXPLIZZ_TEST_DOWNLOAD_FILE="$fixture" FIXPLIZZ_TEST_MODE=1 bash -c "source '$ROOT/install/helpers/artifacts.sh'; fixplizz_install_binary demo https://example.test/demo '$expected' demo"
  [ "$status" -eq 0 ]
  [ -x "$FIXPLIZZ_BIN_HOME/demo" ]
}

@test "MVP modules keep credential and system safety boundaries" {
  run grep -RInE 'sudo[[:space:]]+npm|apt-key|flatpak[[:space:]]+install[[:space:]]+(--system[[:space:]]+)?[^-]|systemctl[[:space:]]+enable[[:space:]]+ssh|apparmor.*(disable|stop)|rustdesk.*password|netbird[[:space:]]+up' "$ROOT/modules" "$ROOT/install/helpers"
  [ "$status" -eq 1 ]
}
