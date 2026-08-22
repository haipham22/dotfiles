

# Resolve dotfiles root from this script's own path (shell/zsh.sh -> root)
DOTFILES_DIR=${0:A:h:h}

export STARSHIP_CONFIG=$DOTFILES_DIR/shell/framework/starship.toml


eval "$(zoxide init zsh)"

source "$DOTFILES_DIR/shell/inc/alias.sh"
source "$DOTFILES_DIR/shell/inc/functions.sh"
source "$DOTFILES_DIR/shell/inc/keybindings.sh"

if [[ "$(uname)" == 'Linux' ]]; then
    source "$DOTFILES_DIR/shell/inc/functions-linux.sh"
fi

# Starship init after zimfw to avoid completion conflicts
eval "$(starship init zsh)"

# mise version manager (PATH-based activation; after zimfw to avoid compinit
# conflicts). Full path: ~/.local/bin may not be on PATH yet at shell init.
# Shims for non-interactive sessions are set up in zprofile.sh.
for _mise in "$HOME/.local/bin/mise" /opt/homebrew/bin/mise /usr/local/bin/mise; do
  [[ -x "$_mise" ]] && eval "$("$_mise" activate zsh)" && break
done


