# Third-Party Notices

## Omabuntu

- Repository: https://github.com/omakasui/omabuntu
- Role: Primary code upstream and PR 1 baseline.
- Baseline commit: `e1bf5f9ed340c6f801937d6bfa1c5c646e2f5368`
- License statement checked: upstream README states MIT License.
- Root license file in checked baseline: not present.

Fixplizz Workstation keeps Omabuntu as the primary code upstream and adapts its Bash-first command router, helpers, phases, channels, backup/migration foundations, diagnostics, and tests.

## Omakub

- Repository: https://github.com/basecamp/omakub
- Role: Architectural origin and donor for reviewed point fixes.
- Checked commit: `c873902f1a5d8b0f54e2e52d565a77274a5941ff`
- License statement checked: upstream README states MIT License.
- Root license file in checked commit: not present.

Omakub must not be merged directly into Fixplizz `main`, `develop`, or `stable`. Any direct code transfer from Omakub must be reviewed, adapted to the Fixplizz/Omabuntu architecture, and documented.
