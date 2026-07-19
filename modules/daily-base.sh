#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd); export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=daily-base
APT_PACKAGES=(poppler-utils ffmpeg)
FLATPAK_APPS=(md.obsidian.Obsidian app.zen_browser.zen org.localsend.localsend_app org.libreoffice.LibreOffice)
VERIFY_COMMANDS=(flatpak pdfinfo ffmpeg)
PLANNED_ACTIONS=('install Obsidian, Zen Browser, LocalSend and LibreOffice from verified user-scoped Flatpak sources')
source "$ROOT/install/helpers/module.sh"
