# Native Ubuntu 26.04 Desktop acceptance

This procedure is the release gate for stable `v0.1.0`. Run it only on a disposable native Ubuntu 26.04 Desktop amd64 machine with GNOME on Wayland. CI, containers and a local `bin/fixplizz` invocation do not replace it.

The harness requires an immutable annotated release tag. It resolves that tag to a full commit SHA, downloads the manifest and `boot.sh` exactly once from commit-addressed GitHub URLs, verifies SHA256, and executes the same saved bytes through the public stdin bootstrap interface.

## Phase 1: public bootstrap and repeatability

Review the plan without changing the host:

```bash
FIXPLIZZ_SMOKE_REF=v0.1.0-rc8 \
  scripts/smoke/native-ubuntu-26.04.sh
```

Execute only after confirming that the machine is disposable:

```bash
FIXPLIZZ_SMOKE_REF=v0.1.0-rc8 \
FIXPLIZZ_NATIVE_SMOKE_ACK=ubuntu-26.04-disposable \
  scripts/smoke/native-ubuntu-26.04.sh --execute
```

Phase 1 performs:

- Ubuntu 26.04, x86_64, GNOME, Wayland, curl, git, sudo and GitHub checks;
- annotated tag resolution to a full commit SHA;
- commit-addressed manifest download followed by a single commit-addressed `boot.sh` download;
- expected and actual SHA256 verification before execution;
- execution of the saved checksum-verified `boot.sh` through `bash -s -- --profile mvp --noninteractive < verified-boot-file`;
- installed `~/.local/bin/fixplizz` version, doctor, status, module and JSON checks;
- capture of the first run ID and sanitized log locations;
- a second installation through the installed CLI;
- comparison of APT sources, keyrings, user Flatpak remotes, shell marker, symlinks, backups and verified artifact fingerprints;
- an isolated test-mode failure/resume exercise in a temporary HOME/XDG fixture;
- creation of `~/.local/state/fixplizz/native-smoke/phase-state.json` and a draft report.

Phase 1 never declares PASS. If logout or reboot is required, complete the exact actions printed by the script.

## Phase 2: after logout/reboot

After the requested logout/relogin and reboot, run:

```bash
FIXPLIZZ_SMOKE_REF=v0.1.0-rc8 \
FIXPLIZZ_SMOKE_LOGOUT_PERFORMED=yes \
FIXPLIZZ_SMOKE_REBOOT_PERFORMED=yes \
  scripts/smoke/native-ubuntu-26.04.sh --verify-after-reboot
```

The harness verifies the installed CLI, PATH, shell integration, GNOME/Wayland, Alacritty, Docker without sudo, Compose v2, mandatory CLI versions, user Flatpak applications, services, persisted run state, complete mandatory modules and absence of unexpected Codex, OpenCode or NetBird authorization.

The following checks remain manual because reliable headless verification is not possible:

- GNOME visual behavior;
- Alacritty window rendering;
- RustDesk launch and authorization state;
- Termix launch and authorization state;
- Obsidian launch;
- NetBird UI when applicable.

After completing every item in `~/.local/state/fixplizz/native-smoke/manual-gui-checklist.txt`, explicitly confirm them:

```bash
FIXPLIZZ_SMOKE_REF=v0.1.0-rc8 \
FIXPLIZZ_SMOKE_LOGOUT_PERFORMED=yes \
FIXPLIZZ_SMOKE_REBOOT_PERFORMED=yes \
FIXPLIZZ_SMOKE_MANUAL_GUI_ACK=gui-checks-passed \
  scripts/smoke/native-ubuntu-26.04.sh --verify-after-reboot
```

Only this final invocation may write `Overall: PASS`. Review the generated report and attach only sanitized logs. Never attach tokens, passwords, environment secrets, SSH private keys, machine credentials or private configuration.
