# Fixplizz Workstation v0.1.0-rc1

Fixplizz Workstation provisions an opinionated developer workstation on Ubuntu 26.04 LTS amd64. The release candidate installs the public `mvp` profile with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/v0.1.0-rc1/boot.sh | bash -s -- --noninteractive
```

Review [`boot.sh`](boot.sh) before running it. This command installs packages and user applications, changes guarded GNOME settings, and may add the current user to the `docker` group. It does not remove Snap, run a distribution upgrade, enable an SSH server, alter AppArmor, create credentials, log into applications, or load private Fixplizz configuration.

## Supported system

- Ubuntu 26.04 LTS only
- x86_64/amd64 only
- GNOME on Wayland is recommended; headless diagnostics remain supported

The ordered profile is `core`, `desktop`, `terminal`, `developer`, `devops-base`, `ai-base`, `daily-base`, and `remote-base`. Vendor artifacts are pinned to HTTPS URLs and verified before installation. Flatpak is always user-scoped.

## Plan, install, resume

```bash
fixplizz install --profile mvp --dry-run
fixplizz install --profile mvp --noninteractive
fixplizz install --profile mvp --resume --noninteractive
fixplizz doctor
fixplizz doctor --json
fixplizz status
fixplizz status --json
```

State and logs are stored below `~/.local/state/fixplizz`; the current run ID is in `current-run`, and the full install log is below `runs/<run-id>/install.log`. Managed configuration uses `~/.config/fixplizz`, downloads use `~/.cache/fixplizz`, and the checkout uses `~/.local/share/fixplizz`. Existing conflicting files are backed up before replacement.

Authentication for Codex, OpenCode, NetBird, RustDesk and Termix is deliberately manual. No credentials, SOPS payloads, private dotfiles or personal profiles are part of this repository.

## Release status

Automated CI covers lint, unit tests, headless integration and the public/private secrets boundary. See [the native smoke procedure](docs/native-smoke-test.md) and [report template](docs/native-smoke-report-template.md).

`v0.1.0 remains blocked` until a real native Ubuntu 26.04 Desktop amd64 smoke report passes. The `v0.1.0-rc1` tag is a prerelease, not stable acceptance.

## Development and attribution

See [development](docs/development.md), [architecture](docs/architecture.md), [upstream attribution](docs/upstream.md), [NOTICE](NOTICE.md), [third-party notices](THIRD_PARTY_NOTICES.md), and [LICENSE](LICENSE).
