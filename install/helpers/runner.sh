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

fixplizz_full_log_path() {
  local run_log="$1"
  printf '%s\n' "${FIXPLIZZ_FULL_LOG:-$run_log}"
}

fixplizz_print_failure_summary() {
  local module="$1" status="$2" run_log="$3"
  local full_log
  full_log="$(fixplizz_full_log_path "$run_log")"
  {
    printf '\n============================================================\n'
    printf 'FIXPLIZZ INSTALLATION FAILED\n'
    printf 'Module: %s\n' "$module"
    printf 'Exit code: %s\n' "$status"
    printf 'Full log: %s\n' "$full_log"
    printf 'Continue: fixplizz resume\n'
    printf '============================================================\n'
  } | tee -a "$run_log" >&2
}

fixplizz_print_success_summary() {
  local profile="$1" run_log="$2" module
  local logout_required=no reboot_required=no full_log
  [[ -e "$FIXPLIZZ_STATE_HOME/logout-required" ]] && logout_required=yes
  [[ -e "$FIXPLIZZ_STATE_HOME/reboot-required" || -e /var/run/reboot-required ]] && reboot_required=yes
  full_log="$(fixplizz_full_log_path "$run_log")"
  {
    printf '\n============================================================\n'
    printf 'FIXPLIZZ INSTALLATION SUCCESS\n'
    printf 'Completed modules:\n'
    while IFS= read -r module; do
      printf '  - %s\n' "$module"
    done < <(fixplizz_profile_modules "$profile")
    printf 'Logout required: %s\n' "$logout_required"
    printf 'Reboot required: %s\n' "$reboot_required"
    printf 'Full log: %s\n' "$full_log"
    printf '============================================================\n'
  } | tee -a "$run_log"
}

fixplizz_run_module_phase_logged() {
  local module="$1" phase="$2" log_file="$3" command_status
  set +e
  fixplizz_module_command "$module" "$phase" 2>&1 | tee -a "$log_file"
  command_status=${PIPESTATUS[0]}
  set -e
  return "$command_status"
}

fixplizz_run_profile() {
  local profile="$1" resume="$2"
  local source_run="" run_id module prior_status log_file module_status

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
      fixplizz_print_failure_summary "$module" 1 "$log_file"
      return 1
    fi

    module_status=0
    fixplizz_run_module_phase_logged "$module" apply "$log_file" || module_status=$?
    if ((module_status == 0)); then
      fixplizz_run_module_phase_logged "$module" verify "$log_file" || module_status=$?
    fi
    if ((module_status != 0)); then
      fixplizz_write_module_state "$run_id" "$module" failed false "apply or verify failed"
      fixplizz_finish_run "$run_id" failed
      fixplizz_print_failure_summary "$module" "$module_status" "$log_file"
      return "$module_status"
    fi
    fixplizz_write_module_state "$run_id" "$module" completed false
  done < <(fixplizz_profile_modules "$profile")

  fixplizz_finish_run "$run_id" completed
  fixplizz_print_success_summary "$profile" "$log_file"
}
