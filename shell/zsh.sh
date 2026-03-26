platform='unknow'
unamestr=`uname`
if [[ "$unamestr" == 'Darkwin' ]]; then
    platform = 'macos'
fi

WOKRSPACE=$HOME/Workspaces

DOTFILES_DIR=$WOKRSPACE/dotfiles

export STARSHIP_CONFIG=$DOTFILES_DIR/shell/framework/starship.toml

# Initialize zimfw FIRST (before any completion setup)
# Guard against double-loading in same session
if [[ -z "$ZIMFW_LOADED" ]]; then
  source "$DOTFILES_DIR/shell/zim.sh"
  export ZIMFW_LOADED=1
fi

# zoxide after zimfw
eval "$(zoxide init zsh)"

source "$DOTFILES_DIR/shell/inc/alias.sh"
source "$DOTFILES_DIR/shell/inc/functions.sh"

# Starship init after zimfw to avoid completion conflicts
eval "$(starship init zsh)"


