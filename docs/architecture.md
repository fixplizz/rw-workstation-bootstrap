# Architecture

## PR 1 Architecture

Fixplizz Workstation PR 1 keeps the Omabuntu repository as the baseline and adds a small public Fixplizz layer.

The public PR 1 layer consists of:

- `bin/fixplizz` command router;
- `bin/fixplizz-*` PR 1 commands;
- `install/helpers/fixplizz-env.sh` runtime path definitions;
- `install/helpers/detection.sh` environment detection;
- `install/helpers/gate.sh` Ubuntu 26.04 x86_64 hard gate;
- docs, notices, tests, and CI.

Legacy `omakub-*` and Omabuntu install scripts remain in the repository for later adaptation, but they are not part of the public PR 1 execution path.

See [legacy-inventory.md](legacy-inventory.md) for retained legacy elements and their PR 1 status.

## Hard Gate

The hard gate accepts only:

```text
ID=ubuntu
VERSION_ID=26.04
architecture=x86_64
```

Hard gate failure returns exit code `3` and must happen before package installation, repository changes, service creation, or user configuration changes.

## Soft Checks

GNOME, Wayland, graphical session, `gsettings`, and `dconf` are diagnostic checks in PR 1. They do not block help, version, commands, doctor, or status. Future desktop operations may require them.

## Exit Codes

```text
0 success
1 internal error
2 unknown command or invalid CLI arguments
3 environment gate failure
4 configuration error
```

## JSON Output

JSON modes write valid JSON to stdout and diagnostics to stderr. JSON output must not be mixed with progress messages.

For `doctor --json`, `ok: false` corresponds to a non-zero exit code. Diagnostic commands may still run on unsupported systems; only mutating install/bootstrap paths enforce the hard gate with exit code `3`.
