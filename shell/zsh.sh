platform='unknow'
unamestr=`uname`
if [[ "$unamestr" == 'Darkwin' ]]; then
    platform = 'macos'
fi

ZNAP_DIR=$HOME/dotfiles/plugins/znap

[[ -f '$ZNAP_DIR/znap.zsh' ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git $ZNAP_DIR


source $ZNAP_DIR/znap.zsh
znap source marlonrichert/zsh-autocomplete
znap source zsh-users/zsh-syntax-highlighting

export STARSHIP_CONFIG=~/dotfiles/shell/framework/starship.toml
eval "$(starship init zsh)"

# alias now='date +"%T"'
