#!/bin/bash

set -Eeuo pipefail

fixplizz_backup_path() {
  local path="$1" stamp backup_dir backup
  [[ -e $path || -L $path ]] || return 0
  stamp="$(date -u +%Y%m%dT%H%M%SZ)-$$-$RANDOM"
  backup_dir="$FIXPLIZZ_STATE_HOME/backups/$stamp"
  mkdir -p "$backup_dir"
  backup="$backup_dir/$(basename -- "$path")"
  cp -a -- "$path" "$backup"
  printf '%s\n' "$backup"
}

fixplizz_managed_symlink() {
  local target="$1" link="$2"
  [[ -e $target ]] || {
    printf 'Symlink target does not exist: %s\n' "$target" >&2
    return 1
  }
  mkdir -p "$(dirname -- "$link")"
  if [[ -L $link ]] && [[ $(readlink -- "$link") == "$target" ]]; then
    return 0
  fi
  if [[ -e $link || -L $link ]]; then
    fixplizz_backup_path "$link" >/dev/null
    rm -f -- "$link"
  fi
  ln -s -- "$target" "$link"
}

fixplizz_install_shell_integration() {
  local rc_file="$1"
  local marker='# FIXPLIZZ MANAGED SHELL'
  local snippet="$FIXPLIZZ_CONFIG_HOME/shell/init.sh"
  mkdir -p "$(dirname -- "$snippet")"
  cat >"$snippet" <<'EOF'
# Managed by Fixplizz Workstation.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/.local/share/mise/shims:"*) ;;
  *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
esac
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
alias h='hermes'
alias agents='herdr'
EOF
  mkdir -p "$(dirname -- "$rc_file")"
  touch "$rc_file"
  if grep -Fq "$marker" "$rc_file"; then
    return 0
  fi
  fixplizz_backup_path "$rc_file" >/dev/null
  cat >>"$rc_file" <<'EOF'

# FIXPLIZZ MANAGED SHELL
[[ -r "$HOME/.config/fixplizz/shell/init.sh" ]] && source "$HOME/.config/fixplizz/shell/init.sh"
EOF
}
