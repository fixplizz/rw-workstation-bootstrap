#!/usr/bin/env bats

setup() {
  export ROOT="$BATS_TEST_DIRNAME/.."
  export CLI="$ROOT/bin/fixplizz"
  export HOME="$BATS_TEST_TMPDIR/home"
  export FIXPLIZZ_STATE_HOME="$BATS_TEST_TMPDIR/state"
  export FIXPLIZZ_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export FIXPLIZZ_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
  export FIXPLIZZ_PATH="$BATS_TEST_TMPDIR/share"
  mkdir -p "$HOME"
}

json_query() {
  python -c 'import json,sys; data=json.load(sys.stdin); exec(sys.argv[1])' "$1"
}

@test "mvp profile resolves the required ordered modules" {
  run "$CLI" module list --profile mvp --json
  [ "$status" -eq 0 ]
  printf '%s' "$output" | json_query 'assert data["ok"] is True; assert data["modules"] == ["core", "desktop", "terminal", "developer", "devops-base", "ai-base", "daily-base", "remote-base"]'
}

@test "install defaults to the mvp profile and noninteractive mode" {
  run env FIXPLIZZ_TEST_MODE=1 "$CLI" install
  [ "$status" -eq 0 ]
  [[ "$output" == *"FIXPLIZZ INSTALLATION SUCCESS"* ]]
  [[ "$output" == *"Completed modules:"* ]]
  [[ "$output" == *"core"* ]]
  [[ "$output" == *"remote-base"* ]]
  [[ "$output" == *"Logout required:"* ]]
  [[ "$output" == *"Reboot required:"* ]]
  [[ "$output" == *"Full log:"* ]]
  run_id="$(<"$FIXPLIZZ_STATE_HOME/current-run")"
  python - "$FIXPLIZZ_STATE_HOME/runs/$run_id/run.json" <<'PY'
import json, pathlib, sys
assert json.loads(pathlib.Path(sys.argv[1]).read_text())["profile"] == "mvp"
PY
  [ "$status" -eq 0 ]
  run bash -c "source '$ROOT/install/helpers/fixplizz-env.sh'; printf '%s:%s\n' \"\$FIXPLIZZ_PROFILE\" \"\$FIXPLIZZ_NONINTERACTIVE\""
  [ "$output" = "mvp:1" ]
}

@test "install rejects an unknown profile" {
  run "$CLI" install --profile missing --dry-run
  [ "$status" -eq 4 ]
  [[ "$output" == *"Unknown Fixplizz profile"* ]]
}

@test "mvp dry-run prints the complete module plan without mutation" {
  run env FIXPLIZZ_TEST_MODE=1 "$CLI" install --profile mvp --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Fixplizz installation plan"* ]]
  [[ "$output" == *"core"* ]]
  [[ "$output" == *"remote-base"* ]]
  [ ! -e "$FIXPLIZZ_STATE_HOME" ]
  [ ! -e "$FIXPLIZZ_CONFIG_HOME" ]
  [ ! -e "$FIXPLIZZ_CACHE_HOME" ]
  [ ! -e "$FIXPLIZZ_PATH" ]
}

@test "test-mode failure records failed state and stops later modules" {
  run env FIXPLIZZ_TEST_MODE=1 FIXPLIZZ_TEST_FAIL_MODULE=terminal \
    "$CLI" install --profile mvp --noninteractive
  [ "$status" -ne 0 ]
  [[ "$output" == *"FIXPLIZZ INSTALLATION FAILED"* ]]
  [[ "$output" == *"Module: terminal"* ]]
  [[ "$output" == *"Exit code: 1"* ]]
  [[ "$output" == *"Full log:"* ]]
  [[ "$output" == *"Continue: fixplizz resume"* ]]

  run_id="$(<"$FIXPLIZZ_STATE_HOME/current-run")"
  python - "$FIXPLIZZ_STATE_HOME/runs/$run_id" <<'PY'
import json, pathlib, sys
run = pathlib.Path(sys.argv[1])
assert json.loads((run / "modules/core.json").read_text())["status"] == "completed"
assert json.loads((run / "modules/desktop.json").read_text())["status"] == "completed"
assert json.loads((run / "modules/terminal.json").read_text())["status"] == "failed"
assert not (run / "modules/developer.json").exists()
PY
}

@test "fixplizz resume continues the last mvp run noninteractively" {
  run env FIXPLIZZ_TEST_MODE=1 FIXPLIZZ_TEST_FAIL_MODULE=terminal "$CLI" install
  [ "$status" -ne 0 ]
  failed_run="$(<"$FIXPLIZZ_STATE_HOME/current-run")"

  run env FIXPLIZZ_TEST_MODE=1 "$CLI" resume
  [ "$status" -eq 0 ]
  [[ "$output" == *"FIXPLIZZ INSTALLATION SUCCESS"* ]]
  resumed_run="$(<"$FIXPLIZZ_STATE_HOME/current-run")"
  [ "$resumed_run" != "$failed_run" ]
  python - "$FIXPLIZZ_STATE_HOME/runs/$resumed_run/run.json" "$failed_run" <<'PY'
import json, pathlib, sys
assert json.loads(pathlib.Path(sys.argv[1]).read_text())["resumed_from"] == sys.argv[2]
PY
}

@test "resume links a new run skips completed modules and retries failure" {
  run env FIXPLIZZ_TEST_MODE=1 FIXPLIZZ_TEST_FAIL_MODULE=terminal \
    "$CLI" install --profile mvp --noninteractive
  [ "$status" -ne 0 ]
  failed_run="$(<"$FIXPLIZZ_STATE_HOME/current-run")"

  run env FIXPLIZZ_TEST_MODE=1 "$CLI" install --profile mvp --resume --noninteractive
  [ "$status" -eq 0 ]
  resumed_run="$(<"$FIXPLIZZ_STATE_HOME/current-run")"
  [ "$resumed_run" != "$failed_run" ]

  python - "$FIXPLIZZ_STATE_HOME/runs/$resumed_run" "$failed_run" <<'PY'
import json, pathlib, sys
run = pathlib.Path(sys.argv[1])
failed = sys.argv[2]
meta = json.loads((run / "run.json").read_text())
assert meta["resumed_from"] == failed
assert json.loads((run / "modules/core.json").read_text())["reused"] is True
assert json.loads((run / "modules/terminal.json").read_text())["status"] == "completed"
assert json.loads((run / "modules/remote-base.json").read_text())["status"] == "completed"
PY
}

@test "failure injection is disabled unless explicit test mode is enabled" {
  run env FIXPLIZZ_TEST_FAIL_MODULE=core bash -c \
    "source '$ROOT/install/helpers/runner.sh' && fixplizz_should_inject_failure core"
  [ "$status" -ne 0 ]
  [[ "$output" != *"No such file"* ]]
  [[ "$output" != *"command not found"* ]]
}

@test "completed module state records source and installed version" {
  run env FIXPLIZZ_TEST_MODE=1 "$CLI" install --profile mvp --noninteractive
  [ "$status" -eq 0 ]
  run_id="$(<"$FIXPLIZZ_STATE_HOME/current-run")"
  python - "$FIXPLIZZ_STATE_HOME/runs/$run_id/modules/core.json" "$ROOT/version" <<'PY'
import json, pathlib, sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
expected_version = pathlib.Path(sys.argv[2]).read_text().strip()
assert data["status"] == "completed"
assert data["installed_version"] == expected_version
assert data["source"] == "profile:core"
PY
}
