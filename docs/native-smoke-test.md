# Native Ubuntu 26.04 Desktop smoke test

Run this only on a disposable, fully updated Ubuntu 26.04 Desktop amd64 machine. CI and containers do not replace this acceptance test.

```bash
scripts/smoke/native-ubuntu-26.04.sh
FIXPLIZZ_NATIVE_SMOKE_ACK=ubuntu-26.04-disposable scripts/smoke/native-ubuntu-26.04.sh --execute
```

After installation, log out if requested, log back in, and reboot if requested. Verify GNOME/Wayland, Alacritty, shell initialization, Docker without sudo, every required CLI `--version`, all installed Flatpak applications, and that RustDesk, Termix, NetBird, Codex and OpenCode remain unauthenticated until the user authorizes them. Re-run install to verify idempotency, inject a test-only failure on a separate mocked run, and confirm `--resume` skips completed modules.

Copy the report template, record the commit and exact host details, attach sanitized logs, and do not include tokens, passwords, private keys or personal configuration.
