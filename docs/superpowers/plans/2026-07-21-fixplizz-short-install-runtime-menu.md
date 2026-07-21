# Fixplizz Short Install and Runtime Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a reliable `https://fixplizz.github.io/install` bootstrap and let users select optional runtimes during or after installation.

**Architecture:** The main bootstrap repository remains the source of truth. `bin/fixplizz-runtime` owns validation, menu parsing, and mise installation; `bin/fixplizz-install` only parses installation flags and exports the selected names for `modules/developer.sh`. The organization Pages repository serves the exact tagged `boot.sh` bytes at `/install`.

**Tech Stack:** Bash 5, Bats, mise, GitHub Pages, GitHub Actions, GitHub CLI.

---

### Task 1: Runtime selection contract

**Files:**
- Modify: `test/fixplizz-cli.bats`
- Modify: `test/fixplizz-mvp.bats`
- Modify: `bin/fixplizz-runtime`
- Modify: `bin/fixplizz-install`

- [ ] Add failing Bats cases proving that `fixplizz runtime menu --print` converts `1,3,8` to `bun java zig`, rejects invalid choices, and does not invoke mise in print mode.
- [ ] Add failing Bats cases proving that `fixplizz install --runtimes bun,java --dry-run` reports the selection and rejects unknown names before creating state.
- [ ] Run the focused Bats tests and confirm failures are caused by missing menu/install arguments.
- [ ] Implement one canonical runtime table and menu parser in `bin/fixplizz-runtime`.
- [ ] Implement `--runtimes` and `--runtime-menu` parsing in `bin/fixplizz-install`; export a space-delimited `FIXPLIZZ_RUNTIMES` value.
- [ ] Run the focused Bats tests and confirm PASS.

### Task 2: Install selected runtimes in the developer module

**Files:**
- Modify: `test/fixplizz-sources.bats`
- Modify: `modules/developer.sh`
- Modify: `install/helpers/runner.sh`

- [ ] Add a failing test that supplies `FIXPLIZZ_RUNTIMES='bun java'` and expects the developer module to invoke `fixplizz-runtime install bun java` after mise is available.
- [ ] Add a failing test that the success summary prints `fixplizz runtime menu` when no optional runtimes were selected.
- [ ] Run the focused tests and confirm RED.
- [ ] Add the selected-runtime call to `module_apply_custom` and the concise next-step hint to the success summary.
- [ ] Run the focused tests and confirm GREEN.

### Task 3: RC6 release metadata and public documentation

**Files:**
- Modify: `version`, `boot.sh`, `docs/install`
- Modify: `config/release-artifacts.rc`, `config/sources.rc`
- Modify: `install/helpers/fixplizz-env.sh`
- Modify: `README.md`, `docs/index.html`, `docs/native-smoke-test.md`
- Modify: release-policy Bats files

- [ ] Change current release references from RC5 to RC6 without editing previous tags.
- [ ] Make the first README command `bash -c 'set -o pipefail; curl -fsSL --retry 3 --retry-all-errors https://fixplizz.github.io/install | bash'`.
- [ ] Document `--runtimes`, `--runtime-menu`, and `fixplizz runtime menu` directly below the default command.
- [ ] Copy `boot.sh` to `docs/install`, verify byte equality, and update `FIXPLIZZ_BOOT_SHA256`.
- [ ] Update policy tests and confirm the fail-safe wrapper returns nonzero for a simulated download failure.

### Task 4: Verify and publish the main RC

**Files:**
- Verify all changed shell, JSON, Markdown, HTML, and release files.

- [ ] Run Bash syntax, ShellCheck, shfmt, all Bats, JSON validation, policy scan, secrets-boundary, UTF-8 scan, and checksum tests.
- [ ] Commit and push `mvp/one-command-workstation` without force.
- [ ] Update draft PR #2 and wait for required CI jobs.
- [ ] Create annotated `v0.1.0-rc6` and a GitHub prerelease only after green CI.
- [ ] Verify RC1–RC5 object and commit hashes remain unchanged and stable `v0.1.0` is absent.

### Task 5: Publish the short endpoint

**Files:**
- Create repository: `fixplizz/fixplizz.github.io`
- Create there: `.nojekyll`, `install`, `index.html`, `README.md`

- [ ] Create the public organization Pages repository if it does not exist.
- [ ] Write `install` from `git show v0.1.0-rc6:boot.sh`; do not use a redirecting wrapper.
- [ ] Add a minimal static landing page with the primary command and runtime-choice examples.
- [ ] Push `main`, enable Pages from `main /`, and wait for deployment.
- [ ] Require HTTP 200, Bash shebang, exact byte equality with tagged RC6, matching SHA256, and a nonzero fail-safe result for simulated curl failure.
