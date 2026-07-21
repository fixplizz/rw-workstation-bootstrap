# Upstream Strategy

## Primary Code Upstream

```text
omakasui/omabuntu
https://github.com/omakasui/omabuntu
```

PR 1 baseline:

```text
commit: e1bf5f9ed340c6f801937d6bfa1c5c646e2f5368
branch: dev at clone time
commit date: 2026-05-18
fork baseline date: 2026-07-16
```

The checked Omabuntu baseline did not contain a root `LICENSE` file. The upstream README states that Omabuntu is released under the MIT License.

## Architectural Origin

```text
basecamp/omakub
https://github.com/basecamp/omakub
```

Checked Omakub commit:

```text
commit: c873902f1a5d8b0f54e2e52d565a77274a5941ff
branch: master at fetch time
```

The checked Omakub commit did not contain a root `LICENSE` file. The upstream README states that Omakub is released under the MIT License.

## Remotes

Use these remotes for Fixplizz development:

```text
origin
    git@github.com:fixplizz/fixplizz-workstation.git

upstream-omabuntu
    https://github.com/omakasui/omabuntu.git

upstream-omakub
    https://github.com/basecamp/omakub.git
```

## Synchronization Rules

`upstream-omabuntu` is the main upstream. Future sync work should use a temporary branch:

```text
sync/omabuntu-YYYY-MM-DD
```

Changes from `upstream-omabuntu` must be reviewed for:

- Fixplizz branding regressions;
- CLI router changes;
- runtime path changes;
- package repository changes;
- Snap policy changes;
- mandatory package changes;
- GDM and Plymouth changes;
- destructive migrations;
- user configuration overwrites;
- Ubuntu 26.04 compatibility.

`upstream-omakub` is only for reviewed point fixes. Do not merge `upstream-omakub/master` directly into Fixplizz `main`, `develop`, or `stable`.

## PR 1 Rebranding Scope

PR 1 adds a public Fixplizz layer while preserving Omabuntu baseline code for future adaptation.

Changed public components:

- README and public documentation;
- public runtime paths;
- public environment variable names;
- public CLI entrypoint `fixplizz`;
- PR 1 command output;
- PR 1 diagnostics.

Preserved historical/upstream references:

- attribution files;
- upstream documentation;
- Git remote names;
- comments explaining source provenance;
- legacy code that is not in the default PR 1 execution path.

Mass unconditional replacement of `omabuntu` or `omakub` across the repository is prohibited.
