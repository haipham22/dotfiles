
# Tool
alias pn=pnpm

# Linux command
alias rm='rm -rf'
alias ll='ls -l'
alias mkdir="mkdir -p"


# git command
alias gpl="git pull"
alias gplb="git pull --rebase"
alias gf="git diff"
alias gst="git status"
alias gcm="git commit"
alias gcma="git commit --amend"
alias gco="git checkout"
alias gph="git push"
alias gcl="git clone"

# command
alias composer="docker run --rm --interactive --tty \
  --volume $PWD:/app \
  --volume ${COMPOSER_HOME:-$HOME/.composer}:/tmp \
  composer"