# Fixplizz Workstation

Fixplizz Workstation is an early Bash-first workstation bootstrap project for Ubuntu 26.04 LTS on x86_64.

This repository is currently at PR 1 scope: fork baseline, public rebranding, Ubuntu 26.04 environment gate, CLI skeleton, diagnostics, tests, and attribution. It is not a production-ready workstation installer yet.

Current acceptance status:

```text
PR 1: implementation complete locally
Acceptance: pending Linux and GitHub Actions validation
```

## Status

- Target OS: Ubuntu 26.04 LTS only.
- Target architecture: x86_64 / amd64 only.
- Public CLI: `fixplizz`.
- Primary code upstream: `omakasui/omabuntu`.
- Architectural origin: `basecamp/omakub`.
- Destructive installation flow is disabled in the default PR 1 path.
- Release stage: development.

PR 1 does not install the full application stack, configure GNOME, connect private configuration, mount Google Drive, or migrate existing Omabuntu/Omakub installations.

## Supported PR 1 Commands

```bash
fixplizz
fixplizz help
fixplizz version
fixplizz commands
fixplizz commands --json
fixplizz commands --check
fixplizz doctor
fixplizz doctor --json
fixplizz status
fixplizz status --json
```

## Runtime Paths

```text
~/.local/share/fixplizz
~/.local/state/fixplizz
~/.config/fixplizz
~/.cache/fixplizz
~/.local/bin/fixplizz
/var/log/fixplizz
/var/lib/fixplizz
```

## Safety Policy

The PR 1 default path does not:

- run full `apt upgrade`;
- remove or block Snap;
- install TLP;
- connect Omabuntu/Omakasui package repositories;
- change GDM or Plymouth;
- change GNOME settings;
- modify firewall or SSH server state;
- overwrite user dotfiles;
- migrate legacy Omabuntu/Omakub installations.

## Bootstrap Status

`boot.sh` is intentionally limited in PR 1. It checks the Ubuntu 26.04 x86_64 hard gate, creates Fixplizz user directories, installs the `~/.local/bin/fixplizz` symlink, and prints the next diagnostic command.

Do not publish `curl | bash` installation instructions for PR 1. The full public bootstrap flow will be designed in a later PR.

## Development

See [docs/development.md](docs/development.md).

## Architecture

See [docs/architecture.md](docs/architecture.md).

## Upstream And License

See [docs/upstream.md](docs/upstream.md), [NOTICE.md](NOTICE.md), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and [LICENSE](LICENSE).
