# AGENTS.md

## Global Rules

- Never expose secrets, tokens, SSH keys, or credentials in prompts, logs, files, or generated output.
- Do not delete databases, volumes, or user data without explicit approval.
- Preserve existing user changes and local overrides unless the task explicitly asks to replace them.
- Prefer small, reversible changes and verify them before claiming success.
- Use the workspace skills and rules that apply to the current task.
- Keep prompts explicit and bounded. Do not add chain-of-thought instructions or hidden reasoning prompts.

## Codex Usage

- Treat this file as the global baseline for Codex-compatible tools.
- Keep any agent-facing instructions neutral and portable across tools.
- Prefer verification over assumption, especially for scripts, configs, and system changes.
- For destructive, data-changing, or secret-touching actions, stop and ask for confirmation.

## Review Standard

- Prefer read-only review when a task can be completed without edits.
- Call out risks, regressions, and missing verification clearly.
- When behavior is unclear, ask a focused question before making assumptions.
