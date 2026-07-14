#!/usr/bin/env bash
# Dev tools helper: installs zoxide, starship, tmux, mise if missing. Idempotent.
# Called by setup.sh (which handles zsh/curl/make base deps + chsh first).
#   macOS : Homebrew
#   Linux : apt (tmux), official install scripts (zoxide/mise -> ~/.local/bin, starship -> /usr/local/bin)
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

install_mac() {
  if ! have brew; then
    echo "❌ Homebrew not found. Install it first: https://brew.sh"
    exit 1
  fi
  have zoxide  || brew install zoxide
  have starship || brew install starship
  have tmux     || brew install tmux
  have mise     || brew install mise
}

install_linux() {
  if ! have curl; then
    echo "📦 Installing curl + ca-certificates (required for downloads)..."
    sudo apt-get update && sudo apt-get install -y curl ca-certificates
  fi
  if ! have zoxide; then
    echo "📦 Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s
  fi
  if ! have starship; then
    echo "📦 Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
  have tmux || { echo "📦 Installing tmux..."; sudo apt-get install -y tmux; }
  have mise || { echo "📦 Installing mise..."; curl -sSfL https://mise.run | sh; }
}

case "$(uname -s)" in
  Darwin) install_mac ;;
  Linux)  install_linux ;;
  *) echo "❌ Unsupported OS: $(uname -s)"; exit 1 ;;
esac

# Verify (also checks common install dirs, since ~/.local/bin may not be on PATH yet).
check() {
  for bin in "$HOME/.local/bin/$1" /usr/local/bin/$1 /opt/homebrew/bin/$1 /usr/bin/$1; do
    [[ -x "$bin" ]] && { echo "✅ $1: $bin"; return; }
  done
  echo "❌ $1: not found (re-run after reloading shell / PATH)"
}

check zoxide
check starship
check tmux
check mise
echo "ℹ️  Run 'exec zsh' to activate."
