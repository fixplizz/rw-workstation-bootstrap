#!/bin/bash

set -Eeuo pipefail

if [[ -z ${FIXPLIZZ_ROOT:-} ]]; then
  FIXPLIZZ_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
  export FIXPLIZZ_ROOT
fi

# shellcheck source=install/helpers/profile.sh
source "$FIXPLIZZ_ROOT/install/helpers/profile.sh"
# shellcheck source=install/helpers/state.sh
source "$FIXPLIZZ_ROOT/install/helpers/state.sh"

fixplizz_should_inject_failure() {
  local module="$1"
  [[ ${FIXPLIZZ_TEST_MODE:-0} == "1" && ${FIXPLIZZ_TEST_FAIL_MODULE:-} == "$module" ]]
}

fixplizz_module_command() {
  local module="$1" phase="$2"
  local file="$FIXPLIZZ_ROOT/modules/$module.sh"
  [[ -x $file ]] || {
    printf 'Missing executable Fixplizz module: %s\n' "$module" >&2
    return 4
  }
  "$file" "$phase"
}

fixplizz_print_plan() {
  local profile="$1" module
  printf 'Fixplizz installation plan\n'
  printf 'Profile: %s\n' "$profile"
  while IFS= read -r module; do
    fixplizz_module_command "$module" plan
  done < <(fixplizz_profile_modules "$profile")
}

fixplizz_run_profile() {
  local profile="$1" resume="$2"
  local source_run="" run_id module prior_status log_file

  if [[ $resume == "true" ]]; then
    [[ -r $FIXPLIZZ_STATE_HOME/current-run ]] || {
      printf 'No Fixplizz run is available to resume.\n' >&2
      return 4
    }
    source_run="$(<"$FIXPLIZZ_STATE_HOME/current-run")"
  fi

  mkdir -p "$FIXPLIZZ_STATE_HOME"
  run_id="$(fixplizz_create_run "$profile" "$source_run")"
  log_file="$FIXPLIZZ_STATE_HOME/runs/$run_id/install.log"

  while IFS= read -r module; do
    if [[ -n $source_run ]]; then
      prior_status="$(fixplizz_read_module_status "$source_run" "$module" 2>/dev/null || true)"
      if [[ $prior_status == "completed" ]]; then
        fixplizz_write_module_state "$run_id" "$module" completed true
        continue
      fi
    fi

    fixplizz_write_module_state "$run_id" "$module" running false
    printf '[%s] running %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$module" | tee -a "$log_file" >&2

    if fixplizz_should_inject_failure "$module"; then
      fixplizz_write_module_state "$run_id" "$module" failed false "test failure injection"
      fixplizz_finish_run "$run_id" failed
      printf 'Module failed: %s; log: %s; resume: fixplizz install --profile %s --resume\n' "$module" "$log_file" "$profile" >&2
      return 1
    fi

    if ! fixplizz_module_command "$module" apply >>"$log_file" 2>&1 || ! fixplizz_module_command "$module" verify >>"$log_file" 2>&1; then
      fixplizz_write_module_state "$run_id" "$module" failed false "apply or verify failed"
      fixplizz_finish_run "$run_id" failed
      printf 'Module failed: %s; log: %s; resume: fixplizz install --profile %s --resume\n' "$module" "$log_file" "$profile" >&2
      return 1
    fi
    fixplizz_write_module_state "$run_id" "$module" completed false
  done < <(fixplizz_profile_modules "$profile")

  fixplizz_finish_run "$run_id" completed
}
