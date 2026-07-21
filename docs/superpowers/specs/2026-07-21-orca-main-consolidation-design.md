# Orca Integration and Main-Branch Consolidation Design

## Goal

Add the official Orca desktop agent IDE to the default Fixplizz Workstation installation, publish the change as a new immutable release candidate, and leave `main` as the only active branch in `fixplizz/rw-workstation-bootstrap`.

## Orca installation

Fixplizz installs the official Ubuntu amd64 package from the immutable Orca `v1.4.148` GitHub release:

- artifact: `orca-ide_1.4.148_amd64.deb`;
- SHA256: `1a2e0defd45584058c394dcea3f709a3953e3bab0530c089ffc25ee3c3c995ac`;
- source: `https://github.com/stablyai/orca/releases/download/v1.4.148/orca-ide_1.4.148_amd64.deb`.

The package is downloaded once, verified before installation, and installed with `apt-get` so package dependencies are resolved by Ubuntu. A state marker makes the operation idempotent. A checksum mismatch prevents package-manager execution.

Orca belongs to `modules/ai-base.sh` and is installed by the default `mvp` profile alongside Codex, OpenCode, and Hermes Agent. Verification accepts the packaged `orca` or `orca-ide` desktop command. Fixplizz writes a user environment file that sets `ORCA_TELEMETRY_DISABLED=1`; it does not create agent credentials or import private configuration.

## Tests and documentation

Bats coverage proves that the source is pinned, checksum validation happens before package installation, mismatch blocks installation, the AI module includes Orca, and the telemetry preference is managed without credentials. README, the Pages landing page, third-party notices, and repository documentation describe Orca and link to its official documentation and MIT-licensed repository.

The full existing validation suite remains the release gate: Bats, Bash syntax, ShellCheck, shfmt, JSON validation, policy scan, secrets-boundary scan, UTF-8/Cyrillic scan, and release checksum checks.

## Release delivery

The change is published as immutable `v0.1.0-rc7`; RC1 through RC6 are not moved or deleted. `boot.sh`, `docs/install`, release artifacts, version metadata, README commands, the repository Pages endpoint, and the short organization endpoint are synchronized to RC7.

## Branch consolidation

The current feature history already contains every commit from `main` and `migration/import-pr1-baseline`. PR #2 is retargeted to `main` and merged after required CI succeeds. Repository Pages is switched to `main /docs`. PR #1 is closed as superseded.

After verifying the merge, default branch, Pages source, release tag, prerelease, and installation endpoints, delete only these remote branches:

- `mvp/one-command-workstation`;
- `migration/import-pr1-baseline`.

Local obsolete project branches are removed only after their commits are shown reachable from `main` or retained by an existing tag/upstream reference. External upstream branches and all release tags remain untouched.
