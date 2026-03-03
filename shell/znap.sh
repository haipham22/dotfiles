
#!/bin/zsh

ZNAP_DIR=$WOKRSPACE/znap-plugins

if [ ! -f "$ZNAP_DIR/znap/znap.zsh" ]; then
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git $ZNAP_DIR/znap
fi

export ZSH_DISABLE_COMPFIX=true

# if [ ! -f "$ZNAP_DIR/modules" ]; then
#     git clone --depth 1 -- \
#         https://github.com/robbyrussell/oh-my-zsh.git $ZNAP_DIR/modules/oh-my-zsh \
#         https://github.com/sorin-ionescu/prezto.git $ZNAP_DIR/modules/prezto
        
# fi


source "$ZNAP_DIR/znap/znap.zsh"

znap prompt sindresorhus/pure

# `znap source` starts plugins.




# Frameworks
znap source mafredri/zsh-async
znap source rupa/z
znap source sorin-ionescu/prezto
znap source sindresorhus/pure
znap source ael-code/zsh-colored-man-pages
znap source momo-lab/zsh-abbrev-alias
znap source Aloxaf/fzf-tab

# znap source robbyrussell/oh-my-zsh
# znap source oh-my-zsh lib/completion


# disable cuz issue in ubuntu
znap source marlonrichert/zsh-autocomplete
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-completions
znap source zsh-users/zsh-syntax-highlighting

if [[ $platform == 'macos' ]]; then
    # `znap eval` caches and runs any kind of command output for you.
    znap eval iterm2 'curl -fsSL https://iterm2.com/shell_integration/zsh'
fi

# `znap function` lets you lazy-load features you don't always need.
# znap function _pyenv pyenv "znap eval pyenv 'pyenv init - --no-rehash'"
# compctl -K    _pyenv pyenv