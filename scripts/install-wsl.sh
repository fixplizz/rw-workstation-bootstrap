#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "install-wsl: $1" >&2
  exit 1
}

need_cmd() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    fail "required command not found: ${command_name}"
  fi
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "${script_dir}/.." && pwd -P)"
zshrc_template="${repo_root}/templates/wsl/zshrc"
wsl_conf_template="${repo_root}/templates/wsl/wsl.conf"

need_cmd sudo
need_cmd bash

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  curl \
  direnv \
  fzf \
  git \
  gnupg \
  jq \
  lsb-release \
  make \
  ripgrep \
  unzip \
  zoxide \
  zsh

if ! command -v fdfind >/dev/null 2>&1; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y fd-find || true
fi

if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"
fi

custom_plugins_dir="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"
mkdir -p "${custom_plugins_dir}"

if [[ ! -d "${custom_plugins_dir}/zsh-autosuggestions" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${custom_plugins_dir}/zsh-autosuggestions"
fi

if [[ ! -d "${custom_plugins_dir}/zsh-syntax-highlighting" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${custom_plugins_dir}/zsh-syntax-highlighting"
fi

if [[ -f "${zshrc_template}" ]]; then
  if [[ -e "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]]; then
    backup="${HOME}/.zshrc.rw-bootstrap.$(date +%Y%m%d%H%M%S).bak"
    cp "${HOME}/.zshrc" "${backup}"
    echo "install-wsl: backed up existing .zshrc to ${backup}"
  fi
  ln -sfn "${zshrc_template}" "${HOME}/.zshrc"
fi

if [[ -f "${wsl_conf_template}" ]]; then
  if [[ -e /etc/wsl.conf && ! -L /etc/wsl.conf ]]; then
    sudo cp /etc/wsl.conf "/etc/wsl.conf.rw-bootstrap.$(date +%Y%m%d%H%M%S).bak"
  fi
  sudo cp "${wsl_conf_template}" /etc/wsl.conf
fi

if [[ "${SHELL:-}" != *"/zsh" ]] && command -v chsh >/dev/null 2>&1; then
  if chsh -s "$(command -v zsh)" 2>/dev/null; then
    echo "install-wsl: default shell changed to zsh"
  else
    echo "install-wsl: could not change default shell automatically; run: chsh -s $(command -v zsh)" >&2
  fi
fi

echo "install-wsl: WSL baseline installed"
