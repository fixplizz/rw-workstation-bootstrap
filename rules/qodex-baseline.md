# Qodex Baseline

This file captures the baseline workstation rules that should apply before any
task-specific policy is layered on top.

## Baseline Rules

- Keep changes narrowly scoped to the requested task.
- Do not expose secrets, tokens, SSH keys, or credentials in files, logs, or
  messages.
- Do not delete databases, wipe data, or copy project assets elsewhere without
  explicit user approval.
- Prefer additive changes and reversible edits when possible.
- Preserve existing user changes unless the task explicitly requires otherwise.

## Notes

- This is a placeholder baseline and may be extended later with more specific
  rules for the workspace.
