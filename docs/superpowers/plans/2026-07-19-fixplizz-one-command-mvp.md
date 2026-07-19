# Fixplizz One-Command Workstation MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, test, and publish a safe one-command Fixplizz Workstation `v0.1.0-rc1` candidate for Ubuntu 26.04 LTS amd64.

**Architecture:** Extend the existing Fixplizz router with a declarative profile, one module runner, focused `plan/check/apply/verify` modules, JSON run state, and injectable system helpers. Keep all real mutation behind non-dry-run helper boundaries so Bats can test behavior in temporary directories without changing the host.

**Tech Stack:** Bash 5, Bats, Python 3 JSON validation, ShellCheck, shfmt, GitHub Actions, Ubuntu APT/deb822, user-scoped Flatpak.

---

### Task 1: Profile and CLI Contract

**Files:**
- Create: `profiles/mvp`
- Create: `bin/fixplizz-install`
- Create: `bin/fixplizz-module-list`
- Create: `install/helpers/profile.sh`
- Create: `test/fixplizz-profile.bats`
- Modify: `bin/fixplizz`
- Modify: `test/run.sh`

- [ ] **Step 1: Write failing profile/router tests**

```bash
@test "mvp profile resolves ordered modules" {
  run "$CLI" module list --profile mvp --json
  [ "$status" -eq 0 ]
  printf '%s' "$output" | json_query 'assert data["modules"] == ["core","desktop","terminal","developer","devops-base","ai-base","daily-base","remote-base"]'
}

@test "install rejects unknown profile" {
  run "$CLI" install --profile missing --dry-run
  [ "$status" -eq 4 ]
}
```

- [ ] **Step 2: Run `bats test/fixplizz-profile.bats` and confirm missing routes fail**
- [ ] **Step 3: Add the exact ordered profile and strict argument parsing for `install` and `module list`**
- [ ] **Step 4: Run profile tests and `bin/fixplizz commands --check`; expect success**
- [ ] **Step 5: Commit with `feat: add MVP profile and install routes`**

### Task 2: Run State and Resume

**Files:**
- Create: `install/helpers/state.sh`
- Create: `install/helpers/runner.sh`
- Create: `test/fixplizz-state.bats`
- Create: `test/fixplizz-resume.bats`
- Modify: `bin/fixplizz-install`

- [ ] **Step 1: Write failing state-transition tests**

```bash
@test "module state transitions pending running completed" {
  run env FIXPLIZZ_TEST_MODE=1 FIXPLIZZ_STATE_HOME="$STATE" "$CLI" install --profile fixture-success
  [ "$status" -eq 0 ]
  python - "$STATE" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
run = (root / "current-run").read_text().strip()
state = json.loads((root / "runs" / run / "modules" / "fixture.json").read_text())
assert state["status"] == "completed"
PY
}
```

- [ ] **Step 2: Run state tests and confirm the state files are missing**
- [ ] **Step 3: Implement atomic JSON state writes, UTC run IDs, sanitized errors, and `current-run`**
- [ ] **Step 4: Write and run a failing resume test using `FIXPLIZZ_TEST_MODE=1` plus `FIXPLIZZ_TEST_FAIL_MODULE`**
- [ ] **Step 5: Implement linked resume runs that skip completed modules and retry incomplete modules**
- [ ] **Step 6: Run state and resume tests; expect all pass**
- [ ] **Step 7: Commit with `feat: add resumable module state engine`**

### Task 3: Non-Mutating Plan and System Helpers

**Files:**
- Create: `install/helpers/plan.sh`
- Create: `install/helpers/packages.sh`
- Create: `install/helpers/repositories.sh`
- Create: `install/helpers/flatpak.sh`
- Create: `install/helpers/files.sh`
- Create: `install/helpers/checksum.sh`
- Create: `test/fixplizz-dry-run.bats`
- Create: `test/fixplizz-sources.bats`
- Modify: `install/helpers/all.sh`

- [ ] **Step 1: Write a failing dry-run mutation test**

```bash
@test "dry-run prints a plan and leaves HOME and state absent" {
  before="$(find "$BATS_TEST_TMPDIR" -mindepth 1 -printf '%P\n' | sort)"
  run env HOME="$HOME" FIXPLIZZ_TEST_MODE=1 "$CLI" install --profile mvp --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"packages"* ]]
  after="$(find "$BATS_TEST_TMPDIR" -mindepth 1 -printf '%P\n' | sort)"
  [ "$before" = "$after" ]
}
```

- [ ] **Step 2: Run the dry-run test and confirm current directory creation fails it**
- [ ] **Step 3: Implement in-memory plan records and human/JSON rendering with no writes**
- [ ] **Step 4: Write failing helper tests for idempotent deb822 content, dedicated keyrings, user Flatpak scope, managed links, backups, and checksum mismatch**
- [ ] **Step 5: Implement helpers with test-mode command injection and no `apt-key`, global Flatpak, or unverified artifact path**
- [ ] **Step 6: Run dry-run and source tests; expect all pass**
- [ ] **Step 7: Commit with `feat: add safe package and source helpers`**

### Task 4: MVP Modules

**Files:**
- Create: `modules/core.sh`
- Create: `modules/desktop.sh`
- Create: `modules/terminal.sh`
- Create: `modules/developer.sh`
- Create: `modules/devops-base.sh`
- Create: `modules/ai-base.sh`
- Create: `modules/daily-base.sh`
- Create: `modules/remote-base.sh`
- Create: `test/fixplizz-modules.bats`
- Modify: `install/helpers/runner.sh`

- [ ] **Step 1: Write failing tests that source every module and assert callable `plan/check/apply/verify` dispatch**
- [ ] **Step 2: Run module tests and confirm missing module files fail**
- [ ] **Step 3: Implement `core`, `desktop`, `terminal`, and `developer` plans and idempotent checks/applies/verifies**
- [ ] **Step 4: Run focused module tests; expect those four modules pass in mocked test mode**
- [ ] **Step 5: Implement `devops-base`, `ai-base`, `daily-base`, and `remote-base` with pinned source metadata and manual-auth notices**
- [ ] **Step 6: Add tests rejecting `sudo npm`, auto-login, SSH server enablement, AppArmor changes, Kitty, and unscoped Flatpak**
- [ ] **Step 7: Run all module and policy tests; expect pass**
- [ ] **Step 8: Commit with `feat: implement MVP workstation modules`**

### Task 5: Bootstrap, Backups, and Shell Integration

**Files:**
- Modify: `boot.sh`
- Modify: `install.sh`
- Modify: `install/helpers/fixplizz-env.sh`
- Create: `test/fixplizz-boot.bats`
- Modify: `test/fixplizz-gate.bats`

- [ ] **Step 1: Write failing tests for prerequisites, network gate, arbitrary cwd, backup-before-replace, safe symlink replacement, argument forwarding, and preserved exit code**
- [ ] **Step 2: Run boot tests and confirm PR1 boot behavior fails them**
- [ ] **Step 3: Implement temporary clone, atomic install replacement, state backup path, and error log reporting without unconditional recursive deletion**
- [ ] **Step 4: Add failing tests for one marked shell source line and backup-before-edit**
- [ ] **Step 5: Implement managed shell snippet and idempotent integration**
- [ ] **Step 6: Run boot, gate, and shell tests; expect pass**
- [ ] **Step 7: Commit with `feat: build safe one-command bootstrap`**

### Task 6: Doctor, Status, and JSON Contracts

**Files:**
- Modify: `bin/fixplizz-doctor`
- Modify: `bin/fixplizz-status`
- Create: `test/fixplizz-json.bats`
- Create: `test/fixplizz-doctor.bats`

- [ ] **Step 1: Write failing JSON schema tests for stable keys and separate OK/WARN/SKIP/FAIL statuses**
- [ ] **Step 2: Run tests and confirm missing MVP state and application checks fail**
- [ ] **Step 3: Implement sanitized doctor checks for OS, sudo, DNS, disk, PATH, checkout, state, APT, Flatpak, Docker, applications, GNOME/Wayland, logout, and reboot**
- [ ] **Step 4: Implement status summaries for current/previous runs and module state without credential output**
- [ ] **Step 5: Run JSON, doctor, CLI, and state tests; expect pass**
- [ ] **Step 6: Commit with `feat: expand diagnostics and JSON status`**

### Task 7: CI, Native Smoke Procedure, and RC Documentation

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `scripts/ci/policy-scan.sh`
- Create: `scripts/ci/secrets-boundary.sh`
- Create: `scripts/smoke/native-ubuntu-26.04.sh`
- Create: `docs/native-smoke-test.md`
- Create: `docs/native-smoke-report-template.md`
- Modify: `README.md`
- Modify: `test/run.sh`

- [ ] **Step 1: Write local policy tests that require the four CI job names and executable smoke/scan scripts**
- [ ] **Step 2: Run policy tests and confirm the old single-job workflow fails**
- [ ] **Step 3: Implement `lint`, `unit`, `integration-headless`, and `secrets-boundary` jobs on `ubuntu-26.04`**
- [ ] **Step 4: Implement the native desktop smoke script and report template without credentials or automatic authorization**
- [ ] **Step 5: Rewrite README with the RC command first, support boundaries, state/log/resume/doctor instructions, and blocked stable command**
- [ ] **Step 6: Run the complete local suite, policy scans, JSON smoke commands, and non-mutating dry-run**
- [ ] **Step 7: Commit with `ci: add RC validation and native smoke procedure`**

### Task 8: Publication and Release Candidate

**Files:**
- Modify only files required by verified CI defects

- [ ] **Step 1: Run `git diff --check`, full tests, ShellCheck, shfmt, policy scan, secrets scan, executable-bit check, JSON checks, and dry-run**
- [ ] **Step 2: Confirm the working tree is clean and record the feature HEAD**
- [ ] **Step 3: Push `mvp/one-command-workstation` without force and verify its remote SHA**
- [ ] **Step 4: Create or update draft PR `Build one-command Fixplizz Workstation MVP` targeting `migration/import-pr1-baseline`**
- [ ] **Step 5: Read GitHub Actions results; reproduce and fix failures with a failing test before each code change**
- [ ] **Step 6: If all mandatory CI jobs pass, create annotated `v0.1.0-rc1`, push that tag without force, and create a GitHub prerelease**
- [ ] **Step 7: Do not create `v0.1.0`; report native Ubuntu 26.04 Desktop smoke as the remaining acceptance blocker**
