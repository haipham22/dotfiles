platform='unknow'
unamestr=`uname`
if [[ "$unamestr" == 'Darkwin' ]]; then
    platform = 'macos'
fi

WOKRSPACE=$HOME/Workspaces

DOTFILES_DIR=$WOKRSPACE/dotfiles

export STARSHIP_CONFIG=$DOTFILES_DIR/shell/framework/starship.toml
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh)"

source "$DOTFILES_DIR/shell/inc/alias.sh"
source "$DOTFILES_DIR/shell/inc/functions.sh"

# source "$DOTFILES_DIR/shell/znap.sh"

source "$DOTFILES_DIR/shell/zim.sh"


