#!/bin/bash

set -Eeuo pipefail

fixplizz_new_run_id() {
  printf '%s-%s-%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" "$$" "$RANDOM"
}

fixplizz_json_write() {
  local path="$1"
  shift
  python - "$path" "$@" <<'PY'
import json, os, pathlib, sys, tempfile
path = pathlib.Path(sys.argv[1])
data = {}
for item in sys.argv[2:]:
    key, value = item.split("=", 1)
    if value == "@true":
        value = True
    elif value == "@false":
        value = False
    elif value == "@null":
        value = None
    data[key] = value
path.parent.mkdir(parents=True, exist_ok=True)
fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
try:
    with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(data, stream, ensure_ascii=False, sort_keys=True)
        stream.write("\n")
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
PY
}

fixplizz_create_run() {
  local profile="$1"
  local resumed_from="${2:-}"
  local run_id run_dir
  run_id="$(fixplizz_new_run_id)"
  run_dir="$FIXPLIZZ_STATE_HOME/runs/$run_id"
  mkdir -p "$run_dir/modules"
  : >"$run_dir/install.log"
  fixplizz_json_write "$run_dir/run.json" \
    "id=$run_id" \
    "profile=$profile" \
    "optional_runtimes=${FIXPLIZZ_RUNTIMES:-}" \
    "status=running" \
    "started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "resumed_from=${resumed_from:-@null}"
  printf '%s\n' "$run_id" >"$FIXPLIZZ_STATE_HOME/current-run"
  printf '%s\n' "$run_id"
}

fixplizz_read_run_runtimes() {
  local path="$FIXPLIZZ_STATE_HOME/runs/$1/run.json"
  [[ -r $path ]] || return 1
  python - "$path" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8")).get("optional_runtimes", ""))
PY
}

fixplizz_module_state_path() {
  printf '%s/runs/%s/modules/%s.json\n' "$FIXPLIZZ_STATE_HOME" "$1" "$2"
}

fixplizz_write_module_state() {
  local run_id="$1" module="$2" status="$3"
  local reused="${4:-false}" reason="${5:-}"
  local installed_version="@null" source="@null"
  if [[ $status == completed ]]; then
    installed_version="$(tr -d '[:space:]' <"$FIXPLIZZ_ROOT/version")"
    source="profile:$module"
  fi
  fixplizz_json_write "$(fixplizz_module_state_path "$run_id" "$module")" \
    "module=$module" \
    "status=$status" \
    "reused=@$reused" \
    "reason=${reason:-@null}" \
    "installed_version=$installed_version" \
    "source=$source" \
    "updated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

fixplizz_read_module_status() {
  local path
  path="$(fixplizz_module_state_path "$1" "$2")"
  [[ -r $path ]] || return 1
  python - "$path" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["status"])
PY
}

fixplizz_finish_run() {
  local run_id="$1" status="$2"
  local path="$FIXPLIZZ_STATE_HOME/runs/$run_id/run.json"
  python - "$path" "$status" <<'PY'
import json, os, pathlib, sys, tempfile
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["status"] = sys.argv[2]
from datetime import datetime, timezone
data["finished_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
    json.dump(data, stream, ensure_ascii=False, sort_keys=True)
    stream.write("\n")
os.replace(temporary, path)
PY
}
