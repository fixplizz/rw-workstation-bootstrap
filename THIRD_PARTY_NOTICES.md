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

## herdr

- Repository: https://github.com/ogulcancelik/herdr
- Installed release: `v0.7.4`, official Linux x86_64 binary.
- Role: local terminal dashboard for coordinating coding agents.
- License: GNU Affero General Public License v3.0 or later, with a commercial licensing option stated upstream.

The installer redistributes no modified herdr source. It downloads the pinned upstream release binary and verifies its SHA256 before installation. The corresponding source is available from the repository and release above.

## Hermes Agent

- Repository: https://github.com/NousResearch/hermes-agent
- Installed package: `hermes-agent==0.18.2`, official PyPI wheel.
- Role: AI agent CLI installed in an isolated `uv` tool environment.
- License: MIT.

Fixplizz does not create Hermes credentials or provider configuration.
