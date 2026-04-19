# AGENTS.md

## Global Rules

- Never expose secrets, tokens, SSH keys, or credentials in prompts, logs, files, or generated output.
- Do not delete databases, volumes, or user data without explicit approval.
- Preserve existing user changes and local overrides unless the task explicitly asks to replace them.
- Prefer small, reversible changes and verify them before claiming success.
- Use the workspace skills and rules that apply to the current task.
- Keep instructions explicit and bounded. Do not add chain-of-thought guidance or hidden reasoning prompts.

## OpenCode Usage

- Treat `~/.config/opencode/opencode.json` as the global config entry point.
- Treat `~/.config/opencode/agents/` as the global agent directory.
- Keep provider keys out of the repository and reference environment variables instead.
- For destructive, data-changing, or secret-touching actions, stop and ask for confirmation.

## Review Standard

- Prefer read-only review when a task can be completed without edits.
- Call out risks, regressions, and missing verification clearly.
- When behavior is unclear, ask a focused question before making assumptions.
