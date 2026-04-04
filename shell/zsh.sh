

WORKSPACE=$HOME/Workspaces

DOTFILES_DIR=$WORKSPACE/dotfiles

export STARSHIP_CONFIG=$DOTFILES_DIR/shell/framework/starship.toml


eval "$(zoxide init zsh)"

source "$DOTFILES_DIR/shell/inc/alias.sh"
source "$DOTFILES_DIR/shell/inc/functions.sh"

if [[ "$(uname)" == 'Linux' ]]; then
    source "$DOTFILES_DIR/shell/inc/functions-linux.sh"
fi

# Starship init after zimfw to avoid completion conflicts
eval "$(starship init zsh)"


