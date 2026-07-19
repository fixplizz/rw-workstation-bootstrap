# Fixplizz native smoke report

- Tester:
- Date/time (UTC):
- RC tag:
- RC commit SHA:
- boot.sh SHA256:
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
- Immutable tag resolution:
- Saved boot artifact:
- boot.sh checksum verification:
- Public one-command bootstrap:
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

PASS requires successful automated phases and explicit confirmation of every manual GUI item. Do not include tokens, passwords, environment secrets, SSH private keys, machine-unique credentials or private configuration.
