# Orca Integration and Main-Branch Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install checksum-verified Orca by default, publish RC7, and consolidate the repository onto `main` as its only active branch.

**Architecture:** Extend the existing pinned-artifact helper with a verified Debian-package installer and invoke it from `ai-base`. Keep the feature branch until tests and CI pass, publish immutable RC7, merge into `main`, switch Pages, and only then delete the two superseded remote branches.

**Tech Stack:** Bash, Bats, apt/dpkg, GitHub Actions, GitHub CLI, GitHub Pages.

---

### Task 1: Record the Orca contract with failing tests

**Files:**
- Modify: `test/fixplizz-sources.bats`
- Modify: `test/fixplizz-policy.bats`

- [ ] Add Bats cases requiring pinned Orca URL/version/SHA256, `ai-base` plan and apply integration, verified `.deb` installation, checksum-mismatch rejection, idempotence, and telemetry opt-out.
- [ ] Run `bats test/fixplizz-sources.bats test/fixplizz-policy.bats` and confirm the new Orca assertions fail because no Orca source or installer exists.

### Task 2: Implement checksum-verified Orca installation

**Files:**
- Modify: `config/sources.rc`
- Modify: `install/helpers/artifacts.sh`
- Modify: `modules/ai-base.sh`

- [ ] Add `ORCA_VERSION`, immutable `ORCA_URL`, and `ORCA_SHA256` to the validated source manifest.
- [ ] Add `fixplizz_install_deb_artifact`, which downloads to a temporary `.deb`, verifies SHA256, runs `sudo apt-get install -y --no-install-recommends "$package"`, records a marker, and cleans up on success or failure.
- [ ] Install Orca from `ai-base`, add the command verification, and manage `~/.config/environment.d/90-fixplizz-orca.conf` containing `ORCA_TELEMETRY_DISABLED=1`.
- [ ] Run the focused Bats files and confirm all new tests pass.

### Task 3: Document Orca and prepare RC7 metadata

**Files:**
- Modify: `README.md`
- Modify: `docs/index.html`
- Modify: `THIRD_PARTY_NOTICES.md`
- Modify: `docs/secrets-repository.md`
- Modify: `version`
- Modify: `boot.sh`
- Modify: `docs/install`
- Modify: `config/release-artifacts.rc`
- Modify: `.github/workflows/ci.yml`

- [ ] Describe Orca as the default desktop agent IDE and link only to `https://www.onorca.dev/docs` and `https://github.com/stablyai/orca`.
- [ ] Change release references from RC6 to RC7 and make `docs/install` byte-identical to `boot.sh`.
- [ ] Restrict branch CI triggers to `main` while retaining pull-request validation.
- [ ] Recompute the release bootstrap SHA256 and run the focused policy/checksum tests.

### Task 4: Run the complete local release gate

**Files:**
- No production files.

- [ ] Run `bash test/run.sh` and require zero failures.
- [ ] Run explicit Bash syntax, ShellCheck, shfmt, JSON, policy, secrets-boundary, UTF-8/Cyrillic, `cmp boot.sh docs/install`, and release checksum checks.
- [ ] Inspect `git diff --check`, `git status --short`, and the complete staged diff.

### Task 5: Publish the feature commit and validate CI

**Files:**
- Commit the files from Tasks 1–3.

- [ ] Commit with `feat: add Orca and consolidate development on main`.
- [ ] Push `mvp/one-command-workstation` without force.
- [ ] Retarget PR #2 from `migration/import-pr1-baseline` to `main`, update its title/body for RC7, and mark it ready for review.
- [ ] Wait for every required PR check and require success before merging.

### Task 6: Merge to main and publish RC7

**Files:**
- Git and GitHub state only, plus the separate local `fixplizz.github.io` endpoint checkout.

- [ ] Merge PR #2 into `main` without rewriting published history and fetch the resulting `main`.
- [ ] Create annotated tag `v0.1.0-rc7` on the merged release commit, push the tag, and create a GitHub prerelease.
- [ ] Switch repository Pages to `main /docs` and wait for a successful deployment.
- [ ] Copy the tagged RC7 `boot.sh` bytes to the organization Pages `/install`, commit, push, wait for deployment, and compare the served bytes and SHA256 with `v0.1.0-rc7:boot.sh`.

### Task 7: Remove superseded branches safely

**Files:**
- Git and GitHub state only.

- [ ] Verify `origin/main` contains both `origin/mvp/one-command-workstation` and `origin/migration/import-pr1-baseline`.
- [ ] Close PR #1 as superseded.
- [ ] Delete the two remote branches without force and prune remote-tracking refs.
- [ ] Remove obsolete local project branches only when their tips are reachable from `main` or preserved by existing tags/upstream refs.
- [ ] Verify GitHub reports `main` as default and the only remote head, Pages uses `main /docs`, RC1–RC6 targets are unchanged, RC7 is a prerelease, and both installation endpoints return HTTP 200.
