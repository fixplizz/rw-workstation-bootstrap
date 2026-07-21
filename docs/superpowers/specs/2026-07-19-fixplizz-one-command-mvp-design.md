# Fixplizz One-Command Workstation MVP Design

## Scope

Build the first public Fixplizz Workstation release candidate on Ubuntu 26.04
LTS amd64. The implementation extends the existing Fixplizz command router and
Omabuntu-derived repository; it does not introduce a parallel installer.

The public MVP excludes private dotfiles, credentials, SOPS payloads, Google
Drive configuration, API keys, and personal profiles.

## Entry Points and Runtime Paths

The supported entry points remain `boot.sh`, `install.sh`, and `bin/fixplizz`.
The installed runtime uses only XDG-aware user paths:

- `~/.local/share/fixplizz` for the checkout and managed assets;
- `~/.local/state/fixplizz` for runs, module state, backups, and current-run;
- `~/.config/fixplizz` for managed user configuration;
- `~/.cache/fixplizz` for disposable downloads;
- `~/.local/bin/fixplizz` for the CLI symlink.

`boot.sh` runs as a normal user, performs the Ubuntu 26.04/x86_64 hard gate
before mutation, validates prerequisites and network access, clones the chosen
`FIXPLIZZ_REPO` and `FIXPLIZZ_REF` into a temporary directory, backs up an
existing installation, installs the new tree atomically, creates the CLI link,
and dispatches `fixplizz install` with the original arguments.

## Installer Architecture

`fixplizz install` resolves a declarative profile and invokes one ordered module
runner. The `mvp` profile contains:

1. `core`
2. `desktop`
3. `terminal`
4. `developer`
5. `devops-base`
6. `ai-base`
7. `daily-base`
8. `remote-base`

Every module exposes `plan`, `check`, `apply`, and `verify`. Shared helpers own
APT packages, deb822 repositories, keyrings, checksums, user Flatpak remotes,
managed symlinks, backups, shell integration, logging, and state. Network and
system boundaries are injectable in test mode so unit tests never modify the
host.

Mandatory modules are sequential and fail fast. `SKIP` is limited to
non-applicable GNOME operations, unavailable GNOME schemas or keys, explicitly
optional operations, and checks that do not apply to the current environment.

## Planning and Dry Run

Each module produces structured plan records for package sources, packages,
repositories, Flatpak applications, GNOME settings, user groups, symlinks, and
backups. `--dry-run` resolves and prints the complete plan without creating
directories or state, invoking sudo, downloading artifacts, changing package
metadata, cloning private repositories, creating services, or changing GNOME.

Human dry-run output is written to stdout. Diagnostics and progress are written
to stderr. JSON commands never mix decoration or logs into stdout.

## State, Logging, Failure, and Resume

Every mutating run gets a UTC run ID and stores data below
`~/.local/state/fixplizz/runs/<run-id>`. `current-run` identifies the latest run.
Module state is JSON and records status, timestamps, installed version, source,
and a short sanitized failure reason. Allowed states are `pending`, `running`,
`completed`, `failed`, and `skipped`.

`--resume` creates a new run linked to the source run. Completed modules are
copied as completed and not executed. Failed, pending, running, missing, and
otherwise incomplete modules run again. A test-only failure injection hook is
honored only when both explicit test mode and a selected module are present.

Logs are visible on the terminal and appended to
`runs/<run-id>/install.log`. Failures report the module, logical action, exit
code, full log path, and exact resume command without exposing credential
values.

## Configuration Safety and Idempotency

Helpers compare desired and current state before changing repositories, keys,
groups, symlinks, PATH entries, Flatpak remotes, and configuration. Existing
user files are backed up before modification. Shell integration is a managed
`~/.config/fixplizz/shell/init.sh` plus one marked source line added after a
backup; reruns never duplicate it.

Flatpak applications use user scope. Docker cleanup, automatic application
login, SSH server enablement, unattended RustDesk passwords, NetBird setup
keys, API key creation, AppArmor changes, GDM changes, Plymouth changes, and
global `sudo npm` are forbidden.

## Source and Version Policy

Ubuntu packages are preferred when suitable. Vendor repositories use HTTPS,
dedicated `/etc/apt/keyrings` keys, and deb822 sources without `apt-key`.
Release artifacts must be amd64, pinned for the RC, and verified with recorded
checksums. HTML release pages are not parsed. The state records the source and
verified installed version. A mandatory application without a verified official
Ubuntu 26.04 amd64 source fails its module.

## Diagnostics

`doctor` and `status` work outside a graphical session. Doctor covers OS,
architecture, sudo availability, network/DNS, disk space, PATH, checkout,
schema and incomplete-run state, APT, Flatpak, Docker, required CLI and GUI
applications, GNOME/Wayland when applicable, and logout/reboot requirements.
Human output distinguishes OK, WARN, SKIP, and FAIL; JSON uses stable fields and
returns non-zero for critical failures.

## Verification and Release

Tests cover routing, hard gate, profile resolution, module transitions, resume,
failure injection, dry-run non-mutation, JSON contracts, idempotent source
helpers, source policy, executable bits, forbidden commands, and secrets
boundaries. All real network and destructive actions are mocked locally.

GitHub Actions provides `lint`, `unit`, `integration-headless`, and
`secrets-boundary` jobs. Headless checks use the available `ubuntu-26.04` runner
and are not represented as GNOME, systemd, Docker daemon, reboot, or native
desktop acceptance.

The repository includes an automated native Ubuntu 26.04 Desktop amd64 smoke
procedure and report template. Without a real passing native run, only the
annotated prerelease tag `v0.1.0-rc1` may be created. The final `v0.1.0` remains
blocked.
