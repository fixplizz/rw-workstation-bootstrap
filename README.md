# Fixplizz Workstation

> One-command workstation bootstrap for Ubuntu 26.04 LTS — development, DevOps, AI, daily tools, and remote work.

[![CI](https://github.com/fixplizz/rw-workstation-bootstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/fixplizz/rw-workstation-bootstrap/actions/workflows/ci.yml)
[![Latest prerelease](https://img.shields.io/github/v/release/fixplizz/rw-workstation-bootstrap?include_prereleases&sort=semver&label=prerelease)](https://github.com/fixplizz/rw-workstation-bootstrap/releases)
[![Ubuntu 26.04 LTS](https://img.shields.io/badge/Ubuntu_26.04_LTS-E95420?logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/26.04/)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Fixplizz turns a clean Ubuntu desktop into a consistent workstation for software development, infrastructure work, AI-assisted coding, daily applications, and remote access.

> [!WARNING]
> **Release Candidate:** `v0.1.0-rc4` is ready for pilot use on supported systems. Stable `v0.1.0` remains blocked until native Ubuntu 26.04 Desktop acceptance passes.

## One-command installation

```bash
bash -c 'set -o pipefail; curl -fsSL --retry 3 https://fixplizz.github.io/rw-workstation-bootstrap/install | bash'
```

Run this command as your regular desktop user. Fixplizz requests `sudo` only for system operations. You do not need to clone the repository or verify a checksum by hand. The installer uses the `mvp` profile in noninteractive mode by default.

If installation stops, continue from the last incomplete module:

```bash
fixplizz resume
```

## What you get

| Area          | Included tools and behavior                                                                                                  |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Core          | Git, curl, wget, jq/yq, ripgrep, fd, bat, fzf, btop, tmux, direnv, Flatpak, ShellCheck, shfmt, SSH client, Wayland clipboard |
| Desktop       | Guarded GNOME defaults, four workspaces, dock click-to-minimize, `~/Applications`                                            |
| Terminal      | Alacritty, Starship, zoxide, JetBrains Mono Nerd Font, tmux, fzf, btop                                                       |
| Development   | GitHub CLI, mise, uv, Node.js LTS, pnpm, Python tooling, Go, Rust, pipx, SQLite, PostgreSQL client, Redis CLI                |
| DevOps        | Docker, Compose, kubectl, Helm, k9s, OpenTofu, Ansible, SOPS, age, Trivy, Gitleaks, Hadolint                                 |
| AI            | OpenAI Codex CLI and OpenCode CLI                                                                                            |
| Daily work    | Obsidian, Zen Browser, LocalSend, LibreOffice, FFmpeg, Poppler                                                               |
| Remote access | NetBird, RustDesk, Termix                                                                                                    |

The `mvp` profile runs modules in this order:

```text
core → desktop → terminal → developer → devops-base → ai-base → daily-base → remote-base
```

## Why Fixplizz

- **One command:** start from a clean supported Ubuntu installation without cloning this repository.
- **Resumable runs:** retry the failed module with `fixplizz resume` instead of starting over.
- **Inspectable state:** each run and module writes structured JSON state.
- **Automatic logs:** bootstrap and module output is available after success or failure.
- **Repeatable operations:** checks and idempotent apply steps avoid unnecessary work.
- **Verified sources:** vendor artifacts use pinned versions and SHA256 checksums.
- **User scope:** Flatpak applications stay in the current user's installation.
- **Explicit authorization:** AI and remote-access tools wait for you to sign in.
- **Public/private split:** the public installer never fetches private Fixplizz configuration.

## Requirements

- Ubuntu 26.04 LTS
- x86_64 / amd64
- Regular user with `sudo`
- Internet connection
- GNOME on Wayland recommended

## Useful commands

```bash
fixplizz status
fixplizz status --json
fixplizz doctor
fixplizz doctor --json
fixplizz commands
fixplizz resume
fixplizz install --profile mvp --dry-run
```

## State, logs and recovery

Fixplizz keeps program files, state, configuration, cache, and the CLI in standard user locations:

```text
~/.local/share/fixplizz
~/.local/state/fixplizz
~/.config/fixplizz
~/.cache/fixplizz
~/.local/bin/fixplizz
```

Every installation run has its own state and log files:

```text
~/.local/state/fixplizz/runs/<run-id>/run.json
~/.local/state/fixplizz/runs/<run-id>/modules/*.json
~/.local/state/fixplizz/runs/<run-id>/install.log
```

On failure, Fixplizz prints the stage or module, exit code, full log path, and the recovery command.

### Technical fallback

If GitHub Pages is unavailable, run the immutable RC4 bootstrap from GitHub Raw:

```bash
bash -c 'set -o pipefail; curl -fsSL --retry 3 https://raw.githubusercontent.com/fixplizz/rw-workstation-bootstrap/v0.1.0-rc4/boot.sh | bash'
```

## Safety boundaries

Fixplizz does not:

- remove or block Snap;
- run a distribution upgrade;
- enable an SSH server;
- weaken AppArmor;
- create credentials;
- sign in to applications on your behalf;
- fetch a private repository;
- overwrite unmanaged user files without creating a backup.

## Architecture

Each module follows the same lifecycle:

```text
plan → check → apply → verify
```

The runner executes ordered modules, stops on the first failure, writes JSON state and logs, backs up conflicting user files, resumes interrupted runs, and keeps repeated operations idempotent.

Maintainer and architecture documentation:

- [Architecture](docs/architecture.md)
- [Development](docs/development.md)
- [Native smoke test](docs/native-smoke-test.md)
- [Secrets repository boundary](docs/secrets-repository.md)
- [Upstream attribution](docs/upstream.md)

## Release status

**Current release:** `v0.1.0-rc4`

Stable v0.1.0 remains blocked until native Ubuntu 26.04 Desktop acceptance passes.

See the [current prerelease and release notes](https://github.com/fixplizz/rw-workstation-bootstrap/releases/tag/v0.1.0-rc4).

## License and attribution

Fixplizz Workstation is available under the [MIT License](LICENSE). See [NOTICE](NOTICE.md), [third-party notices](THIRD_PARTY_NOTICES.md), and [upstream attribution](docs/upstream.md) for retained components and licenses.
