# OpenCode Bootstrap

This repository installs a portable OpenCode baseline into the user's home directory.

## Installed Targets

- `~/.config/opencode/opencode.json`
- `~/.config/opencode/AGENTS.md`
- `~/.config/opencode/agents/reviewer.md`
- `${CODEX_HOME:-~/.codex}/workstation-bootstrap/AGENTS.md`
- `${CODEX_HOME:-~/.codex}/workstation-bootstrap/agents/reviewer.md`

## Behavior

- The installer is idempotent.
- Existing matching symlinks or copied files are left in place.
- Conflicting user files cause a hard failure unless `RW_CODEX_ASSETS_FORCE=1` is set.
- The installer never writes secrets or real API key values.
- Codex-compatible templates are installed under a `workstation-bootstrap/` subdirectory by default so an existing global Codex `AGENTS.md` is not overwritten.
- OpenCode should be launched through `scripts/run-opencode.sh` when provider keys need to be loaded from the private secrets repo.

## Configuration Notes

- OpenCode global config lives at `~/.config/opencode/opencode.json`.
- OpenCode global rules live at `~/.config/opencode/AGENTS.md`.
- OpenCode agent markdown files live under `~/.config/opencode/agents/`.
- Set `RW_CODEX_ASSETS_CODEX_ROOT` if you want Codex-compatible templates installed somewhere other than `${CODEX_HOME:-~/.codex}/workstation-bootstrap`.
- The default OpenCode model routes through local OmniRoute at `http://localhost:20128/v1` using `{env:OMNIROUTE_API_KEY}`.
- The NVIDIA provider uses `@ai-sdk/openai-compatible` with `options.baseURL` and `options.apiKey` referencing `{env:NVIDIA_API_KEY}` as a direct fallback/provider template.

## Verification

- `bash scripts/install-codex-assets.sh --check`
- `bash scripts/install-codex-assets.sh`
