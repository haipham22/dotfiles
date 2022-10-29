
# Tool
alias pn=pnpm

# Linux command
alias rm='rm -rf'
alias ll='ls -l'
alias mkdir="mkdir -p"


# git command
alias gad="git add"
alias gpl="git pull"
alias gplb="git pull --rebase"
alias gf="git diff"
alias gst="git status"
alias gcm="git commit"
alias gcma="git commit --amend"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gph="git push"
alias gcl="git clone"


# docker compose alias
alias dcp="docker compose"
alias dcpe="docker compose exec"
alias dcpd="docker compose down"


# command
alias laravel-init='docker run --rm \
    --pull=always \
    -v "$(pwd)":/opt \
    -w /opt \
    laravelsail/php81-composer:latest \
    bash -c "laravel new example-app"'

alias laravel="composer create-project laravel/laravel --prefer-dist"

alias ng="npx -p @angular/cli@latest ng"
alias cdktf="npx -p cdktf-cli@latest cdktf"