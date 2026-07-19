# Secrets Repository Contract

Fixplizz Workstation uses two independent repositories:

```text
fixplizz/rw-workstation-bootstrap  public bootstrap and system installer
fixplizz/rw-workstation-secrets    private configuration and encrypted secrets
```

The bootstrap repository must work without the secrets repository being present. Commands such as `fixplizz help`, `fixplizz version`, `fixplizz doctor`, and `fixplizz status` must not require private configuration.

## Repository Values

The public contract is declared in:

```text
config/fixplizz/repositories.env
```

Current values:

```text
FIXPLIZZ_BOOTSTRAP_REPO=fixplizz/rw-workstation-bootstrap
FIXPLIZZ_SECRETS_REPO=fixplizz/rw-workstation-secrets
FIXPLIZZ_SECRETS_REPO_SSH=git@github-fixplizz-secrets:fixplizz/rw-workstation-secrets.git
FIXPLIZZ_SECRETS_PATH=$HOME/.local/share/fixplizz/secrets
FIXPLIZZ_SECRETS_SCHEMA_MIN=1
FIXPLIZZ_SECRETS_SCHEMA_MAX=1
```

Do not put deploy key paths, private keys, OAuth tokens, API keys, or user-specific Windows paths in this public contract.

## Ownership Boundary

Bootstrap owns:

- OS installation;
- package management;
- services and system policy;
- public CLI;
- runtime state;
- diagnostics;
- backup, logging, and resume;
- config clone/pull/status/apply engine.

Secrets repository owns:

- personal profile;
- dotfiles;
- application configuration;
- encrypted secrets;
- cloud manifests;
- private hooks.

## Local Clone Path

The intended Linux clone path for the private repository is:

```text
$HOME/.local/share/fixplizz/secrets
```

The bootstrap repository must not assume this path exists. Missing private configuration should be reported as `SKIP` or `WARN` in diagnostics until the user runs the future config commands.

## Schema Compatibility

The secrets repository exposes its schema in:

```text
schema-version
```

For the current contract:

```text
minimum supported schema: 1
maximum supported schema: 1
```

Future `fixplizz config` commands must reject incompatible schema versions before applying private configuration.

## Encryption Policy

Private repository visibility is not sufficient protection for sensitive data.

Plaintext is allowed for non-sensitive configuration such as:

- terminal themes;
- shell aliases;
- tmux and Starship configuration;
- GNOME UI preferences;
- safe application settings.

Sensitive values must be encrypted, preferably with SOPS + age:

- API keys;
- OAuth and refresh tokens;
- passwords;
- NetBird setup keys;
- RustDesk passwords;
- SSH and GPG private keys;
- rclone tokens;
- browser cookies;
- private certificates;
- secret `.env` files.

The bootstrap repository must never copy or log decrypted secret values.

## Future CLI

The following commands are planned after PR 1:

```bash
fixplizz config clone
fixplizz config pull
fixplizz config status
fixplizz config apply
fixplizz config backup
fixplizz config restore
```

Full config application is out of PR 1 scope.
