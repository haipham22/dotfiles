#!/usr/bin/env bash
# One-shot bootstrap. No make required (Ubuntu minimal ships without it).
#   bash setup.sh                 # everything (or: ./setup.sh)
#   bash setup.sh tools           # one phase, e.g. only install dev tools
#   bash setup.sh base chsh inject  # ...or combine phases
# Phases: base chsh tools link inject kanata submodules
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
have() { command -v "$1" >/dev/null 2>&1; }
is_steamos() { [[ -r /etc/os-release ]] && grep -qi 'steamos' /etc/os-release; }

OS="$(uname -s)"

# 1. zsh + tmux + base deps (must come before everything else).
#    On SteamOS, /usr is wiped on every OS update -> re-run `./setup.sh base` after each update.
ensure_base() {
  case "$OS" in
    Darwin)
      have brew || { echo "❌ Homebrew not found: https://brew.sh"; exit 1; }
      have zsh  || brew install zsh
      have tmux || brew install tmux
      ;;
    Linux)
      if is_steamos; then
        steamos_base
      else
        deb_base
      fi
      ;;
    *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
  esac
}

deb_base() {
  if ! have zsh || ! have curl || ! have make || ! have git || ! have tmux; then
    sudo apt-get update
    have zsh  || sudo apt-get install -y zsh
    have curl || sudo apt-get install -y curl ca-certificates
    have make || sudo apt-get install -y make
    have git  || sudo apt-get install -y git
    have tmux || sudo apt-get install -y tmux
  fi
}

steamos_base() {
  local need=()
  have zsh  || need+=(zsh)
  have tmux || need+=(tmux)
  have git  || need+=(git)
  have make || need+=(make)
  have curl || need+=(curl)
  [[ ${#need[@]} -eq 0 ]] && { echo "✅ SteamOS base: all present"; return; }
  echo "📦 SteamOS: disabling read-only root + installing: ${need[*]}"
  sudo steamos-readonly disable
  sudo pacman-key --init
  sudo pacman-key --populate archlinux
  sudo pacman -Sy --noconfirm archlinux-keyring || true
  sudo pacman -S --noconfirm --needed "${need[@]}"
}

# 2. Default shell -> zsh.
#    SteamOS: do NOT chsh to /usr/bin/zsh (wiped on update -> broken login).
#    Launch zsh from ~/.bashrc instead; falls back to bash if zsh is missing.
set_default_shell() {
  local zsh_bin
  zsh_bin="$(command -v zsh || true)"
  [[ -z "$zsh_bin" ]] && { echo "⚠️  zsh not found, skipping"; return; }
  if [[ "$SHELL" == */zsh ]]; then
    echo "✅ default shell already zsh"
    return
  fi
  if is_steamos; then
    local line='[ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null 2>&1 && exec zsh'
    touch "$HOME/.bashrc"
    grep -qF "$line" "$HOME/.bashrc" || printf '\n%s\n' "$line" >> "$HOME/.bashrc"
    echo "✅ SteamOS: 'exec zsh' injected into ~/.bashrc (safe across updates)"
  else
    echo "🐚 Setting default shell to $zsh_bin (password may be required)..."
    chsh -s "$zsh_bin"
  fi
}

# 3. Dev tools: zoxide, starship, mise (user-space, survive SteamOS updates).
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

# 6. Kanata keymapper (Linux only).
install_kanata() {
  [[ "$OS" == "Linux" ]] || { echo "⏭ kanata: Linux only, skipping"; return 0; }
  local kdir="$DOTFILES_DIR/system/linux/kanata"
  if [[ ! -x /usr/local/bin/kanata ]]; then
    local zip="$(mktemp -d)/kanata.zip"
    curl -fsSL -o "$zip" "$(curl -fsSL https://api.github.com/repos/jtroo/kanata/releases/latest \
      | grep -o 'https://[^"]*linux-binaries-x64.zip')"
    local ext="$(dirname "$zip")/ext"
    unzip -oq "$zip" -d "$ext"
    sudo install -m755 "$ext/kanata_linux_x64" /usr/local/bin/kanata
  fi
  sudo groupadd uinput 2>/dev/null || true
  sudo usermod -aG input,uinput "$USER" 2>/dev/null || true
  sudo mkdir -p /etc/kanata
  sudo ln -sfn "$kdir/config.kbd" /etc/kanata/config.kbd
  sudo ln -sfn "$kdir/kanata.service" /etc/systemd/system/kanata.service
  sudo systemctl daemon-reload
  sudo systemctl enable --now kanata
}

# 7. Git submodules.
init_submodules() {
  git -C "$DOTFILES_DIR" submodule update --recursive --init
}

# Subcommands (run individually): base chsh tools link inject submodules
# No args -> run all in order.
dispatch() {
  case "$1" in
    base)       ensure_base ;;
    chsh)       set_default_shell ;;
    tools)      install_tools ;;
    link)       link_configs ;;
    inject)     inject_shell ;;
    kanata)     install_kanata ;;
    submodules) init_submodules ;;
    *) echo "❌ unknown phase: $1"; echo "usage: $0 [base chsh tools link inject kanata submodules]..."; exit 1 ;;
  esac
}

if [[ $# -eq 0 ]]; then
  ensure_base
  set_default_shell
  install_tools
  link_configs
  inject_shell
  install_kanata
  init_submodules
else
  for phase in "$@"; do dispatch "$phase"; done
fi

echo
echo "✅ Done. Restart your shell: exec zsh"
