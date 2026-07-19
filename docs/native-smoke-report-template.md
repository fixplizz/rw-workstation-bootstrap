# Fixplizz native smoke report

- Tester:
- Date/time (UTC):
- Requested RC tag:
- Resolved commit SHA:
- Manifest URL or commit-relative path:
- Boot artifact URL or commit-relative path:
- Expected boot SHA256:
- Actual boot SHA256:
- Verified file path:
- executed_verified_artifact: true / false
- Host hardware:
- GPU:
- Secure Boot:
- Ubuntu version:
- Kernel:
- GNOME version:
- Session type:
- First run ID:
- Second run ID:
- Resume source run ID:
- Resume result run ID:
- Logout performed: yes / no / not required
- Reboot performed: yes / no / not required
- CI run reference:
- Sanitized log locations:

## Automated results

- Host preflight:
- Public artifact downloaded from GitHub:
- Tag resolved to commit:
- Manifest verified:
- Saved boot artifact downloaded exactly once:
- boot.sh checksum verified:
- Verified boot.sh executed through stdin interface:
- Installed CLI checks:
- Doctor JSON validation:
- Status JSON validation:
- First run module statuses:
- Second idempotent run:
- APT source/keyring comparison:
- User Flatpak remote comparison:
- Shell marker/symlink/backup comparison:
- Verified artifact comparison:
- Isolated resume source run:
- Isolated resume result run:
- Resume linkage and reused modules:
- PATH and shell initialization after reboot:
- Docker without sudo and Compose v2:
- Mandatory CLI versions:
- Flatpak applications:
- System/user services:
- Persisted state and complete modules:
- Unexpected AI/remote authorization:

## Manual GUI acceptance

- [ ] GNOME visual behavior
- [ ] Alacritty window launch and rendering
- [ ] RustDesk launch; no unexpected authorization
- [ ] Termix launch; no unexpected authorization
- [ ] Obsidian launch
- [ ] NetBird UI when applicable; no unexpected authorization

## Evidence and result

- Sanitized evidence:
- Failures or warnings:
- Overall: PENDING_AFTER_REBOOT / PENDING_MANUAL_GUI / PASS / FAIL

PASS requires `executed_verified_artifact: true`, matching expected and actual boot SHA256 values, successful automated phases and explicit confirmation of every manual GUI item. Do not include tokens, passwords, environment secrets, authorization headers, SSH private keys, machine-unique credentials or private configuration.
