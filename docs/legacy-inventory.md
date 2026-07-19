# Legacy Inventory

This inventory tracks Omabuntu/Omakub elements retained in PR 1. Retained legacy code is not part of the public Fixplizz PR 1 execution path unless explicitly listed as adapted.

## Status Values

```text
disabled                 present but not called by default
retained                 preserved for attribution or later review
scheduled for adaptation planned for later Fixplizz PR
scheduled for removal    planned for removal after replacement
adapted                  actively used by Fixplizz PR 1
```

## Legacy Commands

| Element | Status | Notes |
|---|---|---|
| `bin/omakub` | disabled | Legacy router remains for source continuity; public PR 1 CLI is `bin/fixplizz`. |
| `bin/omakub-*` | disabled | Not scanned by `bin/fixplizz`; scheduled for adaptation or removal by feature area. |
| `test/omakub-cli-test.sh` | retained | Legacy upstream test; not part of PR 1 validation. |

## Legacy Paths

| Element | Status | Notes |
|---|---|---|
| `~/.local/share/omakub` | disabled | Detected as legacy installation only; never modified or migrated in PR 1. |
| `~/.local/share/omabuntu` | disabled | Detected as legacy installation only; never modified or migrated in PR 1. |
| `themes/*/backgrounds/omabuntu.*` | retained | Static upstream assets retained for later theme review. |

## Legacy Environment Variables

| Element | Status | Notes |
|---|---|---|
| `OMAKUB_PATH` | disabled | Not exported by Fixplizz PR 1. |
| `OMAKUB_REPO` | disabled | Replaced by `FIXPLIZZ_REPO` in PR 1 public layer. |
| `OMAKUB_REF` | disabled | Replaced by `FIXPLIZZ_REF` in PR 1 public layer. |
| `OMAKUB_CHANNEL` | disabled | Replaced by `FIXPLIZZ_CHANNEL` in PR 1 public layer. |
| `OMAKUB_BRAND` | disabled | Replaced by `FIXPLIZZ_BRAND` in PR 1 public layer. |

## Legacy Install Phases

| Element | Status | Notes |
|---|---|---|
| `install/preflight/all.sh` | disabled | Not called by PR 1 `install.sh`; scheduled for adaptation. |
| `install/packaging/all.sh` | disabled | Not called by PR 1 `install.sh`; scheduled for adaptation. |
| `install/config/all.sh` | disabled | Not called by PR 1 `install.sh`; scheduled for adaptation. |
| `install/login/all.sh` | disabled | Not called by PR 1 `install.sh`; scheduled for adaptation. |
| `install/post-install/all.sh` | disabled | Not called by PR 1 `install.sh`; scheduled for adaptation. |

## Legacy Repositories And Package Policies

| Element | Status | Notes |
|---|---|---|
| Omabuntu/Omakasui repositories | disabled | Not connected by PR 1 default path. |
| `install/packaging/remove-snap.sh` | disabled | Snap removal is forbidden in PR 1 default path. |
| inherited TLP behavior | disabled | TLP is not installed by PR 1 default path. |
| inherited `omakub-*` packages | disabled | Full application stack is out of PR 1 scope. |

## Legacy System Policies

| Element | Status | Notes |
|---|---|---|
| GDM changes | disabled | Not executed in PR 1. |
| Plymouth changes | disabled | Not executed in PR 1. |
| GNOME settings changes | disabled | Not executed in PR 1. |
| firewall changes | disabled | Not executed in PR 1. |
| SSH server enablement | disabled | Not executed in PR 1. |
| destructive migrations | disabled | Not executed in PR 1. |

## Adapted PR 1 Components

| Element | Status | Notes |
|---|---|---|
| command discovery/router idea | adapted | Implemented as `bin/fixplizz`, scanning only `fixplizz-*`. |
| metadata validation idea | adapted | Implemented by `fixplizz commands --check`. |
| diagnostics idea | adapted | Implemented by `fixplizz doctor`. |
| status command idea | adapted | Implemented by `fixplizz status`. |
