# Native Ubuntu 26.04 Desktop acceptance

This procedure is the release gate for stable `v0.1.0`. Run it only on a disposable native Ubuntu 26.04 Desktop amd64 machine with GNOME on Wayland. CI, containers and a local `bin/fixplizz` invocation do not replace it.

The harness requires an immutable release tag. It resolves the annotated tag to a commit, downloads `boot.sh` and the checksum manifest from that tag, verifies SHA256, and performs the primary installation through the public one-command interface.

## Phase 1: public bootstrap and repeatability

Review the plan without changing the host:

```bash
FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 \
  scripts/smoke/native-ubuntu-26.04.sh
```

Execute only after confirming that the machine is disposable:

```bash
FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 \
FIXPLIZZ_NATIVE_SMOKE_ACK=ubuntu-26.04-disposable \
  scripts/smoke/native-ubuntu-26.04.sh --execute
```

Phase 1 performs:

- Ubuntu 26.04, x86_64, GNOME, Wayland, curl, git, sudo and GitHub checks;
- immutable tag resolution and `boot.sh` SHA256 verification;
- the published `curl .../${FIXPLIZZ_SMOKE_REF}/boot.sh | bash` bootstrap;
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
FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 \
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
FIXPLIZZ_SMOKE_REF=v0.1.0-rc2 \
FIXPLIZZ_SMOKE_LOGOUT_PERFORMED=yes \
FIXPLIZZ_SMOKE_REBOOT_PERFORMED=yes \
FIXPLIZZ_SMOKE_MANUAL_GUI_ACK=gui-checks-passed \
  scripts/smoke/native-ubuntu-26.04.sh --verify-after-reboot
```

Only this final invocation may write `Overall: PASS`. Review the generated report and attach only sanitized logs. Never attach tokens, passwords, environment secrets, SSH private keys, machine credentials or private configuration.
