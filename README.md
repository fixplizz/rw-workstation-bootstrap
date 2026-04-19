# rw-workstation-bootstrap

Scaffold for workstation bootstrap assets used by the Omniroute companion setup.

## Responsibilities

- keep workstation bootstrap scripts in one place
- store repo-local bootstrap placeholders for WSL, Windows, OmniRoute, OpenCode, Codex, and MCP
- hold template directories that can be filled in by later tasks
- provide a safe landing zone for rules, skills, agents, and docs

## Companion Repo

This repository is meant to work alongside `rw-workstation-secrets`, which holds the companion secret material and operator-specific local state.

`scripts/link-secrets.sh` reads secrets from `RW_SECRETS_DIR` when that variable is set. Otherwise it uses the default companion checkout at `/home/fixplizz/projects/rw-omniroute/rw-workstation-secrets`. The current path contract is documented in `docs/secrets-contract.md`.

By default, `scripts/link-secrets.sh` resolves the active bootstrap checkout from its own location. Set `ROOT_DIR` only if you need to point it at a different bootstrap checkout.

## Main Entry Points

- `scripts/setup-workstation.sh`
- `scripts/install-wsl.sh`
- `scripts/install-windows-tools.sh`
- `scripts/link-secrets.sh`
- `scripts/install-omniroute.sh`
- `scripts/install-opencode.sh`
- `scripts/install-codex-assets.sh`
- `scripts/run-opencode.sh`
- `scripts/smoke-opencode.sh`
- `scripts/test-omniroute-sandbox.sh`
- `scripts/setup-workstation.sh --check`
- `scripts/verify-workstation.sh`
- `scripts/verify-workstation.sh --scaffold-only`
- `scripts/verify-workstation.sh --slice omniroute`
- `scripts/verify-workstation.sh --current`
- `scripts/verify-workstation.sh` (same as `--current`)

`scripts/verify-workstation.sh` is intentionally scoped to the implemented bootstrap surfaces only. It does not claim full workstation readiness yet.
The OmniRoute slice verifier treats `OMNIROUTE_HEALTHCHECK_URL` as a path-like override only, so it always probes the local container health endpoint instead of any arbitrary remote URL.

`scripts/setup-workstation.sh` now supports a preflight check: run `bash scripts/setup-workstation.sh --check` to confirm the checkout can be resolved, the expected setup scripts are present and executable, and the basic toolchain is available. The check exercises repo-root resolution and verifies `bash`, `git`, `docker`, `curl`, and `docker compose`. A successful preflight prints `Preflight OK` and exits 0.

That preflight does not verify the secrets checkout contents, the install steps' internal implementation, or a live OmniRoute container. It is a dependency and layout sanity check, not a full workstation validation.

## Verification

After a fresh bootstrap, run the scaffold check to confirm the repository layout and executable script surface:

```bash
bash scripts/verify-workstation.sh --scaffold-only
```

After machine changes that affect the live OmniRoute install, run the slice check to confirm the linked env file, the running container, and the health endpoint:

```bash
bash scripts/verify-workstation.sh --slice omniroute
```

If you want the currently implemented verification scope in one pass, run:

```bash
bash scripts/verify-workstation.sh --current
```

`--current` runs the scaffold checks first and then the OmniRoute slice check. It is still a scope-limited verification command, not a claim that the whole workstation is ready.
Running `bash scripts/verify-workstation.sh` with no arguments is equivalent to `--current`.

Normal setup stays fail-closed on missing prerequisites or unexpected conflicts. The orchestrator now runs the OpenCode and Codex asset installers as part of the normal setup flow.

Use `bash scripts/link-secrets.sh --check` to validate the expected secrets layout and detect target collisions or unsafe symlinked parent paths without writing links.

## Non-Invasive OmniRoute Test

Use the sandbox test when this machine already has a production/local OmniRoute
container running:

```bash
bash scripts/test-omniroute-sandbox.sh
```

The sandbox uses a separate container name, port, generated local env file, and
Docker volume under `.runtime/`. It does not stop or replace the default
`rw-omniroute` container and does not use provider API keys.

## Status

The OpenCode and Codex asset install steps are now implemented as idempotent, fail-closed installers. They install curated OpenCode config and agent rules into the user's home directory without touching unrelated existing files unless `RW_CODEX_ASSETS_FORCE=1` is set. Codex-compatible templates are installed under `${CODEX_HOME:-~/.codex}/workstation-bootstrap` by default so an existing global Codex `AGENTS.md` is not overwritten.

Run OpenCode through the bootstrap launcher so provider env files from the
private secrets repo are loaded without copying keys into public config:

```bash
bash scripts/run-opencode.sh
```

After configuring OmniRoute providers and a local OmniRoute API key in the
private secrets repo, run the first end-to-end prompt:

```bash
bash scripts/smoke-opencode.sh
```

Important: seeing the entry-point scripts here does not mean setup or verification is complete yet. The current scripts are intentionally scope-limited and should not be treated as proof of a finished workstation bootstrap.
