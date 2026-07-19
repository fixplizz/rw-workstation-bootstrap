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
