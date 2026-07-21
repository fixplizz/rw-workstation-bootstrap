# Fixplizz Workstation PR 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a safe PR 1 baseline from Omabuntu with a public `fixplizz` CLI, Ubuntu 26.04 x86_64 gate, diagnostics, tests, CI, and attribution docs.

**Architecture:** Keep Omabuntu code as baseline and add a small Fixplizz PR1 layer. The public router scans `bin/fixplizz-*` commands only, while legacy `omakub-*` commands stay out of the default execution path. Environment detection lives in `install/helpers/detection.sh` and is mockable only with `FIXPLIZZ_TEST_MODE=1`.

**Tech Stack:** Bash, jq, Bats, ShellCheck, shfmt, GitHub Actions.

---

### Task 1: Baseline And Attribution

**Files:** docs/upstream.md, NOTICE.md, THIRD_PARTY_NOTICES.md, README.md, docs/development.md, docs/architecture.md

- [ ] Record Omabuntu baseline SHA and upstream remotes.
- [ ] Add MIT attribution documents for Omabuntu and Omakub.
- [ ] Document PR1 limitations and development workflow.
- [ ] Commit as `chore: record omabuntu baseline and attribution`.

### Task 2: Fixplizz Runtime Layer

**Files:** install/helpers/fixplizz-env.sh, install/helpers/detection.sh, install/helpers/gate.sh, boot.sh, install.sh

- [ ] Add Fixplizz paths and env defaults.
- [ ] Add mockable environment detection.
- [ ] Add Ubuntu 26.04 x86_64 hard gate.
- [ ] Make `boot.sh` and `install.sh` PR1-safe.
- [ ] Commit as `feat: add fixplizz environment gate`.

### Task 3: CLI Skeleton

**Files:** bin/fixplizz, bin/fixplizz-help, bin/fixplizz-version, bin/fixplizz-commands, bin/fixplizz-doctor, bin/fixplizz-status

- [ ] Add router with command discovery, metadata, JSON, and collision checks.
- [ ] Add PR1 commands and exit code contract.
- [ ] Ensure JSON mode writes only JSON to stdout.
- [ ] Commit as `feat: add fixplizz cli skeleton`.

### Task 4: Tests And CI

**Files:** test/fixplizz-cli.bats, test/fixplizz-gate.bats, test/run.sh, .github/workflows/ci.yml

- [ ] Add Bats tests for CLI, JSON, gate mocks, soft checks, and runtime safety.
- [ ] Add shell validation workflow.
- [ ] Commit as `test: add pr1 cli and gate coverage`.

### Task 5: Verification And Cleanup

**Files:** changed files only

- [ ] Run bash -n, ShellCheck when available, shfmt when available, and Bats tests.
- [ ] Fix failures without expanding PR1 scope.
- [ ] Commit final documentation or cleanup if needed.
