#!/bin/bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export FIXPLIZZ_ROOT="$ROOT"
MODULE_NAME=devops-base
APT_PACKAGES=(ansible age docker.io docker-compose-v2)
FLATPAK_APPS=()
VERIFY_COMMANDS=(docker kubectl helm k9s tofu ansible sops age trivy gitleaks hadolint)
PLANNED_ACTIONS=('install Docker Engine and Compose v2 from Ubuntu' 'install pinned kubectl, Helm, k9s, OpenTofu, SOPS, Trivy, Gitleaks and Hadolint sources' 'idempotently add current user to docker group; logout may be required')
module_apply_custom() {
  [[ ${FIXPLIZZ_TEST_MODE:-0} == 1 ]] && return 0
  fixplizz_install_binary kubectl "$KUBECTL_URL" "$KUBECTL_SHA256" kubectl
  fixplizz_install_tar_binary helm "$HELM_URL" "$HELM_SHA256" linux-amd64/helm helm
  fixplizz_install_tar_binary k9s "$K9S_URL" "$K9S_SHA256" k9s k9s
  fixplizz_install_tar_binary tofu "$TOFU_URL" "$TOFU_SHA256" tofu tofu
  fixplizz_install_binary sops "$SOPS_URL" "$SOPS_SHA256" sops
  fixplizz_install_tar_binary trivy "$TRIVY_URL" "$TRIVY_SHA256" trivy trivy
  fixplizz_install_tar_binary gitleaks "$GITLEAKS_URL" "$GITLEAKS_SHA256" gitleaks gitleaks
  fixplizz_install_binary hadolint "$HADOLINT_URL" "$HADOLINT_SHA256" hadolint
  if ! id -nG "$USER" | tr ' ' '\n' | grep -Fxq docker; then
    sudo usermod -aG docker "$USER"
    mkdir -p "$FIXPLIZZ_STATE_HOME"
    : >"$FIXPLIZZ_STATE_HOME/logout-required"
  fi
}
source "$ROOT/install/helpers/module.sh"
