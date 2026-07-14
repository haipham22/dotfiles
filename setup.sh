#!/usr/bin/env bash
# One-shot bootstrap. No make required (Ubuntu minimal ships without it).
#   bash setup.sh   # or: ./setup.sh
#
# Installs zsh + dev tools, sets zsh as default shell, symlinks configs,
# injects shell sources (~/.zshrc, ~/.zprofile), inits git submodules.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"

# 1. zsh + base deps (must come before everything else).
ensure_base() {
  case "$OS" in
    Darwin)
      have brew || { echo "❌ Homebrew not found: https://brew.sh"; exit 1; }
      have zsh  || brew install zsh
      ;;
    Linux)
      if ! have zsh || ! have curl || ! have make || ! have git; then
        sudo apt-get update
        have zsh  || sudo apt-get install -y zsh
        have curl || sudo apt-get install -y curl ca-certificates
        have make || sudo apt-get install -y make
        have git  || sudo apt-get install -y git
      fi
      ;;
    *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
  esac
}

# 2. Default shell -> zsh (skip if already).
set_default_shell() {
  local zsh_bin
  zsh_bin="$(command -v zsh || true)"
  [[ -z "$zsh_bin" ]] && { echo "⚠️  zsh not found, skipping chsh"; return; }
  if [[ "$SHELL" == */zsh ]]; then
    echo "✅ default shell already zsh"
  else
    echo "🐚 Setting default shell to $zsh_bin (password may be required)..."
    chsh -s "$zsh_bin"
  fi
}

# 3. Dev tools: zoxide, starship, tmux, mise.
install_tools() {
  bash "$DOTFILES_DIR/shell/inc/install-tools.sh"
}

# 4. Symlinks + git global ignores.
link_configs() {
  ln -sfn "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
  git config --global core.excludesfile "$DOTFILES_DIR/git/.gitignore"
}

# 5. Inject shell sources (idempotent). Order: zimfw BEFORE zoxide/starship.
append_once() {  # <file> <line>
  touch "$1"
  grep -qF "$2" "$1" || echo "$2" >> "$1"
}
inject_shell() {
  append_once "$HOME/.zshrc"    "source \"$DOTFILES_DIR/shell/zim.sh\""
  append_once "$HOME/.zshrc"    "source \"$DOTFILES_DIR/shell/zsh.sh\""
  append_once "$HOME/.zprofile" "source \"$DOTFILES_DIR/shell/zprofile.sh\""
}

# 6. Git submodules.
init_submodules() {
  git -C "$DOTFILES_DIR" submodule update --recursive --init
}

ensure_base
set_default_shell
install_tools
link_configs
inject_shell
init_submodules

echo
echo "✅ Done. Restart your shell: exec zsh"
