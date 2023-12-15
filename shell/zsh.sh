platform='unknow'
unamestr=`uname`
if [[ "$unamestr" == 'Darkwin' ]]; then
    platform = 'macos'
fi


DOTFILES_DIR=$HOME/dotfiles

ZNAP_DIR=$HOME/.znap-plugins

if [ ! -f "$ZNAP_DIR/znap/znap.zsh" ]; then
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git $ZNAP_DIR/znap
fi

source "$DOTFILES_DIR/shell/inc/alias.sh"
source "$DOTFILES_DIR/shell/inc/functions.sh"

source "$ZNAP_DIR/znap/znap.zsh"

znap prompt sindresorhus/pure

# `znap source` starts plugins.
znap source marlonrichert/zsh-autocomplete

znap source zsh-users/zsh-completions
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting

# `znap eval` caches and runs any kind of command output for you.
znap eval iterm2 'curl -fsSL https://iterm2.com/shell_integration/zsh'

export STARSHIP_CONFIG=~/dotfiles/shell/framework/starship.toml
eval "$(starship init zsh)"
