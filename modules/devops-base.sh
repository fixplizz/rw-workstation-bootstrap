#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd); export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=devops-base
APT_PACKAGES=(ansible age)
FLATPAK_APPS=()
VERIFY_COMMANDS=(docker kubectl helm k9s tofu ansible sops age trivy gitleaks hadolint)
PLANNED_ACTIONS=('add official Docker deb822 source and compose plugin' 'install pinned kubectl, Helm, k9s, OpenTofu, SOPS, Trivy, Gitleaks and Hadolint sources' 'idempotently add current user to docker group; logout may be required')
source "$ROOT/install/helpers/module.sh"
