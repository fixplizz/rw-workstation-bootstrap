# AGENTS.md - rw-workstation-bootstrap

## Mission
Work only inside `rw-workstation-bootstrap` unless a separate root-level task explicitly expands the scope.

## Rules
1. Do not commit secrets, decrypted files, real tokens, private keys, or production `.env` files.
2. Keep `rw-workstation-secrets` outside this workspace; reference it only through the documented secrets contract.
3. Do not change existing secret paths or bootstrap paths without a migration plan.
4. Do not run workstation setup scripts that modify the host unless the user explicitly asks for that action.
5. Update docs when changing script behavior.

## Workflow
1. Read `README.md`, `docs/secrets-contract.md`, and the relevant script before editing.
2. Prefer idempotent shell scripts with `set -euo pipefail`.
3. Keep bootstrap logic separated from secret material.
4. Report changed files and validation commands.

