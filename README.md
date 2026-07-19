# Fixplizz Workstation v0.1.0-rc4

Fixplizz Workstation provisions an opinionated developer workstation on Ubuntu 26.04 LTS amd64. The release candidate installs the public `mvp` profile with one command:

```bash
bash -c 'set -o pipefail; curl -fsSL --retry 3 https://fixplizz.github.io/rw-workstation-bootstrap/install | bash'
```

No repository clone, separate `boot.sh` download, manual checksum verification, profile selection or smoke-test command is required. The release defaults to the public `mvp` profile and noninteractive installation. This command installs packages and user applications, changes guarded GNOME settings, and may add the current user to the `docker` group. It does not remove Snap, run a distribution upgrade, enable an SSH server, alter AppArmor, create credentials, log into applications, or load private Fixplizz configuration.

Technical fallback through the immutable GitHub Raw release artifact:

```bash
bash -c 'set -o pipefail; curl -fsSL --retry 3 https://raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/v0.1.0-rc4/boot.sh | bash'
```

## Supported system

- Ubuntu 26.04 LTS only
- x86_64/amd64 only
- GNOME on Wayland is recommended; headless diagnostics remain supported

The ordered profile is `core`, `desktop`, `terminal`, `developer`, `devops-base`, `ai-base`, `daily-base`, and `remote-base`. Vendor artifacts are pinned to HTTPS URLs and verified before installation. Flatpak is always user-scoped.

## Continue after an interruption

```bash
fixplizz resume
```

Bootstrap and installation output is logged automatically below `~/.local/state/fixplizz`. On failure Fixplizz prints the failed stage or module, exit code, full log path and the exact continuation command. The current run ID is in `current-run`; managed configuration uses `~/.config/fixplizz`, downloads use `~/.cache/fixplizz`, and the checkout uses `~/.local/share/fixplizz`.

Authentication for Codex, OpenCode, NetBird, RustDesk and Termix is deliberately manual. No credentials, SOPS payloads, private dotfiles or personal profiles are part of this repository.

## Release status

Automated CI covers lint, unit tests, headless integration and the public/private secrets boundary.

`v0.1.0 remains blocked` until a real native Ubuntu 26.04 Desktop amd64 smoke report passes. The `v0.1.0-rc4` tag is a prerelease, not stable acceptance. The immutable `v0.1.0-rc1`, `v0.1.0-rc2` and `v0.1.0-rc3` tags remain available as previous candidates.

## Development and attribution

Native acceptance is a maintainer workflow documented separately in [the native smoke procedure](docs/native-smoke-test.md) and [report template](docs/native-smoke-report-template.md); ordinary users do not run it.

The public installation endpoint is served from GitHub Pages. After this branch is merged, the Pages source must be changed from `mvp/one-command-workstation /docs` to `main /docs` in repository settings.

See [development](docs/development.md), [architecture](docs/architecture.md), [upstream attribution](docs/upstream.md), [NOTICE](NOTICE.md), [third-party notices](THIRD_PARTY_NOTICES.md), and [LICENSE](LICENSE).
