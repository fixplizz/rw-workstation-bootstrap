#!/usr/bin/env bash

set -Eeuo pipefail

REPOSITORY_SLUG=fixplizz/rw-workstation-bootstrap
REPOSITORY_URL=https://github.com/fixplizz/rw-workstation-bootstrap.git
INSTALLED_CLI="$HOME/.local/bin/fixplizz"
SMOKE_PYTHON="${FIXPLIZZ_SMOKE_PYTHON:-python3}"
SMOKE_STATE_HOME="${FIXPLIZZ_SMOKE_STATE_HOME:-$HOME/.local/state/fixplizz/native-smoke}"
PHASE_STATE="$SMOKE_STATE_HOME/phase-state.json"
REPORT_FILE="$SMOKE_STATE_HOME/native-smoke-report.md"
AUTOMATION_LOG="$SMOKE_STATE_HOME/automation.log"
VERSIONS_FILE="$SMOKE_STATE_HOME/tool-versions.txt"
GUI_CHECKLIST_FILE="$SMOKE_STATE_HOME/manual-gui-checklist.txt"

RC_COMMIT_SHA="${RC_COMMIT_SHA:-pending}"
BOOT_SHA256="${BOOT_SHA256:-pending}"
FIRST_RUN_ID="${FIRST_RUN_ID:-pending}"
SECOND_RUN_ID="${SECOND_RUN_ID:-pending}"
RESUME_SOURCE_RUN_ID="${RESUME_SOURCE_RUN_ID:-pending}"
RESUME_RESULT_RUN_ID="${RESUME_RESULT_RUN_ID:-pending}"
LOGOUT_REQUIRED="${LOGOUT_REQUIRED:-unknown}"
REBOOT_REQUIRED="${REBOOT_REQUIRED:-unknown}"

smoke_fail() {
  local code="$1"
  shift
  printf 'FAIL: %s\n' "$*" >&2
  return "$code"
}

smoke_require_ref() {
  [[ -n ${FIXPLIZZ_SMOKE_REF:-} ]] || smoke_fail 2 'FIXPLIZZ_SMOKE_REF is required (for example v0.1.0-rc2).'
  case "$FIXPLIZZ_SMOKE_REF" in
    main | master | latest | refs/heads/* | */latest | *latest/*)
      smoke_fail 2 "FIXPLIZZ_SMOKE_REF must be an immutable release tag, not $FIXPLIZZ_SMOKE_REF."
      ;;
  esac
  [[ $FIXPLIZZ_SMOKE_REF =~ ^v[0-9]+\.[0-9]+\.[0-9]+-rc[0-9]+$ ]] ||
    smoke_fail 2 'FIXPLIZZ_SMOKE_REF must be an immutable RC tag such as v0.1.0-rc2.'
}

smoke_os_field() {
  local field="$1"
  local os_file="${FIXPLIZZ_SMOKE_OS_RELEASE:-/etc/os-release}"
  (
    set +u
    # shellcheck disable=SC1090
    source "$os_file"
    case "$field" in
      id) printf '%s\n' "${ID:-unknown}" ;;
      version) printf '%s\n' "${VERSION_ID:-unknown}" ;;
    esac
  )
}

smoke_arch() {
  if [[ ${FIXPLIZZ_SMOKE_TEST_MODE:-0} == 1 && -n ${FIXPLIZZ_SMOKE_ARCH:-} ]]; then
    printf '%s\n' "$FIXPLIZZ_SMOKE_ARCH"
  else
    uname -m
  fi
}

smoke_desktop() {
  if [[ ${FIXPLIZZ_SMOKE_TEST_MODE:-0} == 1 && -n ${FIXPLIZZ_SMOKE_DESKTOP:-} ]]; then
    printf '%s\n' "$FIXPLIZZ_SMOKE_DESKTOP"
  else
    printf '%s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
  fi
}

smoke_session() {
  if [[ ${FIXPLIZZ_SMOKE_TEST_MODE:-0} == 1 && -n ${FIXPLIZZ_SMOKE_SESSION:-} ]]; then
    printf '%s\n' "$FIXPLIZZ_SMOKE_SESSION"
  else
    printf '%s\n' "${XDG_SESSION_TYPE:-unknown}"
  fi
}

smoke_validate_host() {
  local os_id version arch desktop session
  os_id="$(smoke_os_field id)"
  version="$(smoke_os_field version)"
  arch="$(smoke_arch)"
  desktop="$(smoke_desktop)"
  session="$(smoke_session)"
  [[ $os_id == ubuntu && $version == 26.04 ]] || smoke_fail 3 "Native smoke requires Ubuntu 26.04; detected $os_id $version."
  [[ $arch == x86_64 ]] || smoke_fail 3 "Native smoke requires x86_64; detected $arch."
  [[ $desktop == *GNOME* ]] || smoke_fail 3 "Native smoke requires GNOME Desktop; detected $desktop."
  [[ $session == wayland ]] || smoke_fail 3 "Native smoke requires Wayland; detected $session."
}

smoke_require_tools_and_network() {
  local command
  for command in curl git "$SMOKE_PYTHON" sha256sum sudo; do
    command -v "$command" >/dev/null 2>&1 || smoke_fail 5 "Required command is unavailable: $command"
  done
  [[ ${FIXPLIZZ_SMOKE_TEST_MODE:-0} == 1 ]] && return 0
  curl -fsSI --retry 3 --connect-timeout 10 https://github.com >/dev/null || smoke_fail 5 'GitHub is unreachable.'
  sudo -v || smoke_fail 5 'sudo authorization failed.'
}

smoke_print_plan() {
  cat <<EOF
Fixplizz native acceptance plan
  immutable ref: $FIXPLIZZ_SMOKE_REF
  public boot: https://raw.githubusercontent.com/$REPOSITORY_SLUG/$FIXPLIZZ_SMOKE_REF/boot.sh
  phase 1: verify artifact, public bootstrap, installed CLI checks, second run, isolated resume
  phase 2: post-logout/reboot CLI, GNOME, Docker, Flatpak, service and authorization checks
  report: $REPORT_FILE
EOF
}

smoke_fetch_release_artifact() {
  local boot_url manifest_url boot_file manifest_file expected_sha refs
  boot_url="https://raw.githubusercontent.com/$REPOSITORY_SLUG/${FIXPLIZZ_SMOKE_REF}/boot.sh"
  manifest_url="https://raw.githubusercontent.com/$REPOSITORY_SLUG/${FIXPLIZZ_SMOKE_REF}/config/release-artifacts.rc"
  boot_file="$SMOKE_STATE_HOME/boot-${FIXPLIZZ_SMOKE_REF}.sh"
  manifest_file="$SMOKE_STATE_HOME/release-artifacts-${FIXPLIZZ_SMOKE_REF}.rc"

  mkdir -p "$SMOKE_STATE_HOME"
  refs="$(git ls-remote --tags "$REPOSITORY_URL" "refs/tags/$FIXPLIZZ_SMOKE_REF" "refs/tags/$FIXPLIZZ_SMOKE_REF^{}")"
  RC_COMMIT_SHA="$(printf '%s\n' "$refs" | awk -v ref="refs/tags/$FIXPLIZZ_SMOKE_REF^{}" '$2 == ref {print $1}')"
  [[ $RC_COMMIT_SHA =~ ^[0-9a-f]{40}$ ]] ||
    smoke_fail 6 "Cannot resolve $FIXPLIZZ_SMOKE_REF as an immutable annotated tag."

  curl -fsSL --retry 3 "$boot_url" -o "$boot_file"
  curl -fsSL --retry 3 "$manifest_url" -o "$manifest_file"
  expected_sha="$(awk -F= '$1 == "FIXPLIZZ_BOOT_SHA256" {print $2}' "$manifest_file")"
  [[ $expected_sha =~ ^[0-9a-f]{64}$ ]] || smoke_fail 6 'Release manifest does not contain FIXPLIZZ_BOOT_SHA256.'
  BOOT_SHA256="$(sha256sum "$boot_file" | awk '{print $1}')"
  [[ $BOOT_SHA256 == "$expected_sha" ]] || smoke_fail 6 "boot.sh SHA256 mismatch: expected $expected_sha, got $BOOT_SHA256."
  chmod 0755 "$boot_file"
  printf 'Verified %s at commit %s with boot.sh SHA256 %s.\n' "$FIXPLIZZ_SMOKE_REF" "$RC_COMMIT_SHA" "$BOOT_SHA256"
}

smoke_run_cli_checks() {
  local prefix="$1" installed_version expected_version
  installed_version="$("$INSTALLED_CLI" version)"
  expected_version="Fixplizz Workstation ${FIXPLIZZ_SMOKE_REF#v}"
  [[ $installed_version == "$expected_version" ]] ||
    smoke_fail 7 "Installed CLI version $installed_version does not match requested release $expected_version."
  printf '%s\n' "$installed_version" | tee -a "$AUTOMATION_LOG"
  "$INSTALLED_CLI" doctor | tee -a "$AUTOMATION_LOG"
  "$INSTALLED_CLI" doctor --json | tee "$SMOKE_STATE_HOME/${prefix}-doctor.json" | "$SMOKE_PYTHON" -m json.tool >/dev/null
  "$INSTALLED_CLI" status | tee -a "$AUTOMATION_LOG"
  "$INSTALLED_CLI" status --json | tee "$SMOKE_STATE_HOME/${prefix}-status.json" | "$SMOKE_PYTHON" -m json.tool >/dev/null
  "$INSTALLED_CLI" module list | tee "$SMOKE_STATE_HOME/${prefix}-modules.txt" >/dev/null
}

smoke_current_run_id() {
  local state_home="${FIXPLIZZ_STATE_HOME:-$HOME/.local/state/fixplizz}"
  [[ -r "$state_home/current-run" ]] || smoke_fail 7 'Installed CLI did not record current-run.'
  tr -d '[:space:]' <"$state_home/current-run"
}

smoke_snapshot_idempotency() {
  local destination="$1"
  "$SMOKE_PYTHON" - "$HOME" "$destination" <<'PY'
import hashlib
import json
import os
import pathlib
import subprocess
import sys

home = pathlib.Path(sys.argv[1])
destination = pathlib.Path(sys.argv[2])

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def files(pattern):
    result = []
    for path in sorted(pathlib.Path("/").glob(pattern.lstrip("/"))):
        if path.is_file():
            result.append({"path": str(path), "sha256": digest(path)})
    return result

def command(*args):
    try:
        return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL).strip().splitlines()
    except (FileNotFoundError, subprocess.CalledProcessError):
        return []

bin_names = ["fixplizz", "fd", "bat", "starship", "zoxide", "mise", "uv", "kubectl", "helm", "k9s", "tofu", "sops", "trivy", "gitleaks", "hadolint", "codex", "opencode", "netbird"]
links = {}
artifacts = {}
for name in bin_names:
    path = home / ".local" / "bin" / name
    if path.is_symlink():
        links[name] = os.readlink(path)
    elif path.is_file():
        artifacts[name] = {"sha256": digest(path), "mtime_ns": path.stat().st_mtime_ns}

rc = home / ".bashrc"
data = {
    "apt_sources": files("etc/apt/sources.list.d/*.sources"),
    "keyrings": files("etc/apt/keyrings/*"),
    "flatpak_remotes": command("flatpak", "remote-list", "--user", "--columns=name,url"),
    "shell_marker_count": rc.read_text(errors="replace").count("# FIXPLIZZ MANAGED SHELL") if rc.exists() else 0,
    "links": links,
    "artifacts": artifacts,
    "backup_file_count": sum(1 for p in (home / ".local/state/fixplizz/backups").glob("**/*") if p.is_file()),
}
destination.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY
}

smoke_compare_idempotency() {
  local first="$1" second="$2"
  if ! diff -u "$first" "$second" >"$SMOKE_STATE_HOME/idempotency.diff"; then
    smoke_fail 8 "Second run changed managed sources, remotes, markers, links, backups or compatible artifacts; see $SMOKE_STATE_HOME/idempotency.diff."
  fi
}

smoke_run_resume_fixture() {
  local fixture source_run result_run failed_status
  fixture="$(mktemp -d "${TMPDIR:-/tmp}/fixplizz-resume-smoke.XXXXXX")"
  mkdir -p "$fixture/home"
  set +e
  HOME="$fixture/home" \
    FIXPLIZZ_STATE_HOME="$fixture/state" \
    FIXPLIZZ_CONFIG_HOME="$fixture/config" \
    FIXPLIZZ_CACHE_HOME="$fixture/cache" \
    FIXPLIZZ_PATH="$fixture/share" \
    FIXPLIZZ_BIN_HOME="$fixture/bin" \
    FIXPLIZZ_TEST_MODE=1 \
    FIXPLIZZ_TEST_FAIL_MODULE=terminal \
    "$INSTALLED_CLI" install --profile mvp --noninteractive >>"$AUTOMATION_LOG" 2>&1
  failed_status=$?
  set -e
  [[ $failed_status -ne 0 ]] || smoke_fail 9 'Resume fixture failure injection unexpectedly succeeded.'
  source_run="$(tr -d '[:space:]' <"$fixture/state/current-run")"

  "$SMOKE_PYTHON" - "$fixture/state/runs/$source_run" <<'PY'
import json, pathlib, sys
run = pathlib.Path(sys.argv[1])
assert json.loads((run / "modules/core.json").read_text())["status"] == "completed"
assert json.loads((run / "modules/desktop.json").read_text())["status"] == "completed"
assert json.loads((run / "modules/terminal.json").read_text())["status"] == "failed"
assert not (run / "modules/developer.json").exists()
PY

  HOME="$fixture/home" \
    FIXPLIZZ_STATE_HOME="$fixture/state" \
    FIXPLIZZ_CONFIG_HOME="$fixture/config" \
    FIXPLIZZ_CACHE_HOME="$fixture/cache" \
    FIXPLIZZ_PATH="$fixture/share" \
    FIXPLIZZ_BIN_HOME="$fixture/bin" \
    FIXPLIZZ_TEST_MODE=1 \
    "$INSTALLED_CLI" install --profile mvp --resume --noninteractive >>"$AUTOMATION_LOG" 2>&1
  result_run="$(tr -d '[:space:]' <"$fixture/state/current-run")"

  "$SMOKE_PYTHON" - "$fixture/state/runs/$result_run" "$source_run" <<'PY'
import json, pathlib, sys
run = pathlib.Path(sys.argv[1])
source = sys.argv[2]
meta = json.loads((run / "run.json").read_text())
assert meta["status"] == "completed"
assert meta["resumed_from"] == source
assert json.loads((run / "modules/core.json").read_text())["reused"] is True
assert json.loads((run / "modules/terminal.json").read_text())["status"] == "completed"
PY

  RESUME_SOURCE_RUN_ID="$source_run"
  RESUME_RESULT_RUN_ID="$result_run"
  rm -rf -- "$fixture"
}

smoke_host_value() {
  local command="$1" fallback="$2" value
  value="$(bash -c "$command" 2>/dev/null | head -n 1 | tr -d '\r' || true)"
  printf '%s\n' "${value:-$fallback}"
}

smoke_write_phase_state() {
  "$SMOKE_PYTHON" - "$PHASE_STATE" "$FIXPLIZZ_SMOKE_REF" "$RC_COMMIT_SHA" "$BOOT_SHA256" "$FIRST_RUN_ID" "$SECOND_RUN_ID" "$RESUME_SOURCE_RUN_ID" "$RESUME_RESULT_RUN_ID" "$LOGOUT_REQUIRED" "$REBOOT_REQUIRED" <<'PY'
import json, os, pathlib, sys, tempfile
path = pathlib.Path(sys.argv[1])
data = {
    "schema": 1,
    "phase": "pending-after-reboot",
    "rc_tag": sys.argv[2],
    "rc_commit_sha": sys.argv[3],
    "boot_sha256": sys.argv[4],
    "first_run_id": sys.argv[5],
    "second_run_id": sys.argv[6],
    "resume_source_run_id": sys.argv[7],
    "resume_result_run_id": sys.argv[8],
    "logout_required": sys.argv[9],
    "reboot_required": sys.argv[10],
}
path.parent.mkdir(parents=True, exist_ok=True)
fd, temporary = tempfile.mkstemp(prefix=".phase-state.", dir=path.parent)
with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
    json.dump(data, stream, indent=2, sort_keys=True)
    stream.write("\n")
os.replace(temporary, path)
PY
}

smoke_load_phase_state() {
  local requested_ref="${FIXPLIZZ_SMOKE_REF:-}"
  [[ -r $PHASE_STATE ]] || smoke_fail 4 "Cannot run after-reboot verification without phase state: $PHASE_STATE"
  mapfile -t state_values < <(
    "$SMOKE_PYTHON" - "$PHASE_STATE" <<'PY' | tr -d '\r'
import json, pathlib, sys
d = json.loads(pathlib.Path(sys.argv[1]).read_text())
for key in ("phase", "rc_tag", "rc_commit_sha", "boot_sha256", "first_run_id", "second_run_id", "resume_source_run_id", "resume_result_run_id", "logout_required", "reboot_required"):
    print(d.get(key, ""))
PY
  )
  [[ ${state_values[0]:-} == pending-after-reboot ]] || smoke_fail 4 'Saved phase state is not pending after reboot.'
  if [[ -n $requested_ref && $requested_ref != "${state_values[1]}" ]]; then
    smoke_fail 4 "Requested release ref $requested_ref does not match saved phase ref ${state_values[1]}."
  fi
  FIXPLIZZ_SMOKE_REF="${state_values[1]}"
  export FIXPLIZZ_SMOKE_REF
  RC_COMMIT_SHA="${state_values[2]}"
  BOOT_SHA256="${state_values[3]}"
  FIRST_RUN_ID="${state_values[4]}"
  SECOND_RUN_ID="${state_values[5]}"
  RESUME_SOURCE_RUN_ID="${state_values[6]}"
  RESUME_RESULT_RUN_ID="${state_values[7]}"
  LOGOUT_REQUIRED="${state_values[8]}"
  REBOOT_REQUIRED="${state_values[9]}"
}

smoke_write_report() {
  local report="$1" overall="$2"
  local hardware gpu secure_boot ubuntu kernel gnome session logout_performed reboot_performed ci_reference versions_summary
  hardware="$(smoke_host_value "lscpu | sed -n 's/^Model name:[[:space:]]*//p'" unknown)"
  gpu="$(smoke_host_value "lspci | grep -Ei 'VGA|3D|Display'" unknown)"
  secure_boot="$(smoke_host_value 'mokutil --sb-state' unknown)"
  ubuntu="$(smoke_os_field version 2>/dev/null || printf unknown)"
  kernel="$(uname -r 2>/dev/null || printf unknown)"
  gnome="$(smoke_host_value 'gnome-shell --version' unknown)"
  session="$(smoke_session 2>/dev/null || printf unknown)"
  logout_performed="${FIXPLIZZ_SMOKE_LOGOUT_PERFORMED:-no}"
  reboot_performed="${FIXPLIZZ_SMOKE_REBOOT_PERFORMED:-no}"
  ci_reference="${FIXPLIZZ_SMOKE_CI_RUN_REFERENCE:-https://github.com/fixplizz/rw-workstation-bootstrap/pull/2/checks}"
  versions_summary="$(test -r "$VERSIONS_FILE" && sed -E 's/(token|secret|password|key)[^[:space:]]*/[redacted]/Ig' "$VERSIONS_FILE" || printf 'pending')"

  "$SMOKE_PYTHON" - "$report" "$overall" "${FIXPLIZZ_SMOKE_REF:-pending}" "$RC_COMMIT_SHA" "$BOOT_SHA256" "$hardware" "$gpu" "$secure_boot" "$ubuntu" "$kernel" "$gnome" "$session" "$FIRST_RUN_ID" "$SECOND_RUN_ID" "$RESUME_SOURCE_RUN_ID" "$RESUME_RESULT_RUN_ID" "$logout_performed" "$reboot_performed" "$ci_reference" "$versions_summary" <<'PY'
import pathlib, sys
(path, overall, tag, commit, boot_sha, hardware, gpu, secure_boot, ubuntu, kernel,
 gnome, session, first_run, second_run, resume_source, resume_result, logout,
 reboot, ci_reference, versions) = sys.argv[1:]
text = f"""# Fixplizz native smoke report

- RC tag: {tag}
- RC commit SHA: {commit}
- boot.sh SHA256: {boot_sha}
- Host hardware: {hardware}
- GPU: {gpu}
- Secure Boot: {secure_boot}
- Ubuntu version: {ubuntu}
- Kernel: {kernel}
- GNOME version: {gnome}
- Session type: {session}
- First run ID: {first_run}
- Second run ID: {second_run}
- Resume source run ID: {resume_source}
- Resume result run ID: {resume_result}
- Logout performed: {logout}
- Reboot performed: {reboot}
- CI run reference: {ci_reference}
- Sanitized smoke artifacts: ~/.local/state/fixplizz/native-smoke/

## Automated acceptance

- Immutable annotated tag resolved: {"PASS" if commit != "pending" else "PENDING"}
- Downloaded boot.sh checksum verification: {"PASS" if boot_sha != "pending" else "PENDING"}
- Public bootstrap run: {"PASS" if first_run != "pending" else "PENDING"}
- First install log: ~/.local/state/fixplizz/runs/{first_run}/install.log
- Installed CLI verification: {"PASS" if first_run != "pending" else "PENDING"}
- First status summary: ~/.local/state/fixplizz/native-smoke/first-status.json
- First module summary: ~/.local/state/fixplizz/native-smoke/first-modules.txt
- Second installed-CLI run: {"PASS" if second_run != "pending" else "PENDING"}
- Second install log: ~/.local/state/fixplizz/runs/{second_run}/install.log
- Second status summary: ~/.local/state/fixplizz/native-smoke/second-status.json
- Second module summary: ~/.local/state/fixplizz/native-smoke/second-modules.txt
- Idempotency snapshot comparison: {"PASS" if second_run != "pending" else "PENDING"}
- Isolated resume run: {"PASS" if resume_result != "pending" else "PENDING"} ({resume_source} -> {resume_result})
- Post-logout/reboot checks: {"PASS" if overall in ("PASS", "PENDING_MANUAL_GUI") else "PENDING"}

## Installed tool versions

```text
{versions}
```

## Manual GUI acceptance

- [ ] GNOME visual behavior
- [ ] Alacritty window launch and rendering
- [ ] RustDesk launch; no unexpected authorization
- [ ] Termix launch; no unexpected authorization
- [ ] Obsidian launch
- [ ] NetBird UI, when applicable; no unexpected authorization

## Result

- Overall: {overall}
- PASS is forbidden until every manual GUI item is explicitly confirmed.
"""
path = pathlib.Path(path)
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(text, encoding="utf-8", newline="\n")
PY
}

smoke_record_tool_versions() {
  local command
  : >"$VERSIONS_FILE"
  for command in fixplizz git curl jq rg fzf btop tmux direnv shellcheck shfmt flatpak alacritty starship zoxide gh mise uv node pnpm python3 go rustc cargo pipx sqlite3 psql redis-cli docker kubectl helm k9s tofu ansible sops age trivy gitleaks hadolint codex opencode netbird; do
    if command -v "$command" >/dev/null 2>&1; then
      printf '%s: ' "$command" >>"$VERSIONS_FILE"
      "$command" --version 2>&1 | head -n 1 | tr -d '\r' >>"$VERSIONS_FILE" || printf 'version command unavailable\n' >>"$VERSIONS_FILE"
    else
      printf '%s: MISSING\n' "$command" >>"$VERSIONS_FILE"
    fi
  done
}

smoke_verify_after_reboot() {
  local app current_run auth_failure=0
  smoke_load_phase_state
  smoke_validate_host
  smoke_require_tools_and_network
  [[ -x $INSTALLED_CLI ]] || smoke_fail 10 "Installed CLI is missing: $INSTALLED_CLI"
  [[ :$PATH: == *":$HOME/.local/bin:"* ]] || smoke_fail 10 "$HOME/.local/bin is absent from PATH."
  [[ -r "$HOME/.config/fixplizz/shell/init.sh" ]] || smoke_fail 10 'Managed shell initialization is missing.'
  [[ $(grep -c '# FIXPLIZZ MANAGED SHELL' "$HOME/.bashrc") -eq 1 ]] || smoke_fail 10 'Shell source marker is missing or duplicated.'
  command -v alacritty >/dev/null 2>&1 || smoke_fail 10 'Alacritty is unavailable.'
  docker info >/dev/null 2>&1 || smoke_fail 10 'Docker is not usable without sudo.'
  docker compose version >/dev/null 2>&1 || smoke_fail 10 'Docker Compose v2 is unavailable.'
  systemctl is-active --quiet docker || smoke_fail 10 'Docker service is not active.'
  systemctl --user is-system-running >/dev/null 2>&1 || true

  smoke_run_cli_checks after-reboot
  smoke_record_tool_versions
  if grep -q ': MISSING$' "$VERSIONS_FILE"; then
    smoke_fail 10 "Mandatory CLI tools are missing; see $VERSIONS_FILE."
  fi

  for app in md.obsidian.Obsidian app.zen_browser.zen org.localsend.localsend_app org.libreoffice.LibreOffice com.rustdesk.RustDesk com.karmaa.termix; do
    flatpak info --user "$app" >/dev/null 2>&1 || smoke_fail 10 "Required user Flatpak is missing: $app"
  done

  current_run="$(smoke_current_run_id)"
  "$SMOKE_PYTHON" - "$HOME/.local/state/fixplizz/runs/$current_run/modules" <<'PY'
import json, pathlib, sys
files = list(pathlib.Path(sys.argv[1]).glob("*.json"))
assert len(files) == 8
assert all(json.loads(path.read_text())["status"] == "completed" for path in files)
PY

  [[ -e "$HOME/.codex/auth.json" ]] && auth_failure=1
  [[ -e "$HOME/.local/share/opencode/auth.json" || -e "$HOME/.config/opencode/auth.json" ]] && auth_failure=1
  netbird status 2>/dev/null | grep -Eqi 'connected|management: connected' && auth_failure=1
  ((auth_failure == 0)) || smoke_fail 10 'Unexpected AI or remote-tool authorization was detected.'

  cat >"$GUI_CHECKLIST_FILE" <<'EOF'
[ ] GNOME visual behavior is correct
[ ] Alacritty window launches and renders correctly
[ ] RustDesk launches and remains manually controlled
[ ] Termix launches and remains manually controlled
[ ] Obsidian launches
[ ] NetBird UI is correct when applicable and has no unexpected authorization
EOF
  printf 'Manual GUI checklist:\n'
  cat "$GUI_CHECKLIST_FILE"

  if [[ ${FIXPLIZZ_SMOKE_MANUAL_GUI_ACK:-} != gui-checks-passed ]]; then
    smoke_write_report "$REPORT_FILE" PENDING_MANUAL_GUI
    printf 'Automatic phase 2 checks passed, but native acceptance is not PASS. Complete %s and rerun with FIXPLIZZ_SMOKE_MANUAL_GUI_ACK=gui-checks-passed.\n' "$GUI_CHECKLIST_FILE"
    return 2
  fi

  if [[ $LOGOUT_REQUIRED == yes && ${FIXPLIZZ_SMOKE_LOGOUT_PERFORMED:-} != yes ]]; then
    smoke_fail 10 'Logout was required but not explicitly confirmed.'
  fi
  if [[ $REBOOT_REQUIRED == yes && ${FIXPLIZZ_SMOKE_REBOOT_PERFORMED:-} != yes ]]; then
    smoke_fail 10 'Reboot was required but not explicitly confirmed.'
  fi
  smoke_write_report "$REPORT_FILE" PASS
  printf 'Native acceptance PASS recorded in %s.\n' "$REPORT_FILE"
}

smoke_execute_phase_one() {
  local boot_url first_snapshot second_snapshot
  [[ ${FIXPLIZZ_NATIVE_SMOKE_ACK:-} == ubuntu-26.04-disposable ]] ||
    smoke_fail 2 'Set FIXPLIZZ_NATIVE_SMOKE_ACK=ubuntu-26.04-disposable before --execute.'
  smoke_validate_host
  smoke_require_tools_and_network
  smoke_print_plan
  smoke_fetch_release_artifact
  : >"$AUTOMATION_LOG"

  boot_url="https://raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/${FIXPLIZZ_SMOKE_REF}/boot.sh"
  curl -fsSL --retry 3 "$boot_url" | bash -s -- --profile mvp --noninteractive
  [[ -x $INSTALLED_CLI ]] || smoke_fail 7 "Public bootstrap did not install $INSTALLED_CLI."
  smoke_run_cli_checks first
  FIRST_RUN_ID="$(smoke_current_run_id)"
  first_snapshot="$SMOKE_STATE_HOME/first-idempotency.json"
  second_snapshot="$SMOKE_STATE_HOME/second-idempotency.json"
  smoke_snapshot_idempotency "$first_snapshot"

  "$INSTALLED_CLI" install --profile mvp --noninteractive
  smoke_run_cli_checks second
  SECOND_RUN_ID="$(smoke_current_run_id)"
  [[ $SECOND_RUN_ID != "$FIRST_RUN_ID" ]] || smoke_fail 8 'Second installation did not create a distinct run ID.'
  smoke_snapshot_idempotency "$second_snapshot"
  smoke_compare_idempotency "$first_snapshot" "$second_snapshot"
  smoke_run_resume_fixture

  LOGOUT_REQUIRED=no
  REBOOT_REQUIRED=no
  [[ -e "$HOME/.local/state/fixplizz/logout-required" ]] && LOGOUT_REQUIRED=yes
  [[ -e "$HOME/.local/state/fixplizz/reboot-required" || -e /var/run/reboot-required ]] && REBOOT_REQUIRED=yes
  smoke_record_tool_versions
  smoke_write_phase_state
  smoke_write_report "$REPORT_FILE" PENDING_AFTER_REBOOT

  printf 'Phase 1 completed without declaring PASS.\n'
  printf 'First run: %s\nSecond run: %s\nResume: %s -> %s\n' "$FIRST_RUN_ID" "$SECOND_RUN_ID" "$RESUME_SOURCE_RUN_ID" "$RESUME_RESULT_RUN_ID"
  printf 'Phase state: %s\nDraft report: %s\n' "$PHASE_STATE" "$REPORT_FILE"
  [[ $LOGOUT_REQUIRED == yes ]] && printf 'Required next action: log out and log back in.\n'
  [[ $REBOOT_REQUIRED == yes ]] && printf 'Required next action: reboot the machine.\n'
  printf 'Then run: FIXPLIZZ_SMOKE_REF=%s scripts/smoke/native-ubuntu-26.04.sh --verify-after-reboot\n' "$FIXPLIZZ_SMOKE_REF"
}

smoke_main() {
  local mode=plan
  case "${1:-}" in
    '') ;;
    --execute) mode=execute ;;
    --verify-after-reboot) mode=after-reboot ;;
    *) smoke_fail 2 'Usage: native-ubuntu-26.04.sh [--execute|--verify-after-reboot]' ;;
  esac

  if [[ $mode == after-reboot ]]; then
    [[ -r $PHASE_STATE ]] || smoke_fail 4 "Cannot run after-reboot verification without phase state: $PHASE_STATE"
    smoke_verify_after_reboot
    return
  fi

  smoke_require_ref
  smoke_validate_host
  if [[ $mode == execute ]]; then
    [[ ${FIXPLIZZ_NATIVE_SMOKE_ACK:-} == ubuntu-26.04-disposable ]] ||
      smoke_fail 2 'Set FIXPLIZZ_NATIVE_SMOKE_ACK=ubuntu-26.04-disposable before --execute.'
  fi
  smoke_print_plan
  [[ $mode == plan ]] && return 0
  smoke_execute_phase_one
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  smoke_main "$@"
fi
