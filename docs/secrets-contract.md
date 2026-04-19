# Secrets Contract

`scripts/link-secrets.sh` links runtime-facing files inside `rw-workstation-bootstrap` to the operator-managed secrets stored in the companion `rw-workstation-secrets` repository.

## Default Paths

- Bootstrap root defaults to the active `rw-workstation-bootstrap` checkout.
- Secrets repo defaults to `$RW_SECRETS_DIR` when set, otherwise the sibling `rw-workstation-secrets` checkout next to `rw-workstation-bootstrap`.

## Required Source Files

The current contract requires this source file to exist before linking:

- OmniRoute env source: `${SECRETS_DIR}/env/omniroute/.env`

If the secrets directory is missing, or if the OmniRoute env file does not exist, `scripts/link-secrets.sh` exits with code `1` and prints a clear error.

## Runtime Targets

The linker manages this runtime target inside the bootstrap repository:

- OmniRoute env target: `${ROOT_DIR}/bootstrap/omniroute/.env.local`

In normal mode the script creates the target parent directory and symlinks `.env.local` to the companion secrets file.

If the target already exists as a regular file, directory entry, or symlink to a different destination, the script fails closed with a clear error. Only an already-matching symlink is accepted as valid.

The target parent path must also stay inside the bootstrap repository path. The script fails if the immediate parent directory is a symlink, or if resolving the parent path would escape the intended bootstrap root through a symlinked ancestor.

## Modes

- `bash scripts/link-secrets.sh --check`
  Validates the secrets directory, required files, and resolved target paths without changing files. This also checks whether the target path is safe to link, so `--check` will fail on collisions or symlink-parent escapes that would block a real run.
- `bash scripts/link-secrets.sh`
  Performs the same validation, then creates the OmniRoute symlink and prints what was linked.

## Overrides

Set `RW_SECRETS_DIR` to point at a non-default secrets checkout:

```bash
RW_SECRETS_DIR=/custom/path/rw-workstation-secrets bash scripts/link-secrets.sh --check
```
