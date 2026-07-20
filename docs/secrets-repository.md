# Secrets repository boundary

The public Fixplizz Workstation repository contains installer code, pinned public artifact metadata, tests, and documentation. It does not contain credentials, encrypted personal payloads, private dotfiles, or application sessions.

The public installer does not fetch a private repository. Authentication for Codex, OpenCode, Hermes Agent, herdr integrations, NetBird, RustDesk, Termix, and other user accounts remains a manual step after installation.

Keep private configuration in a separate access-controlled repository. Review that repository's authorization, encryption, and recovery model before connecting it to a workstation workflow.

CI runs `scripts/ci/secrets-boundary.sh` to detect common credential material in the public tree. This scan supports review; it does not replace secret rotation or repository access controls.
