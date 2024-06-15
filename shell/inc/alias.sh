
# Tool
alias pn=pnpm

# Linux command
alias rm='rm -rf'
alias ll='ls -l'
alias mkdir="mkdir -p"
alias cls="clear"

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
alias dcpu="docker compose up"
alias dcpud="docker compose up -d"
alias dcpe="docker compose exec"
alias dcpd="docker compose down"
alias dcpdv="docker compose down -v"

# command
alias laravel-init='docker run --rm \
    --pull=always \
    -v "$(pwd)":/opt \
    -w /opt \
    laravelsail/php81-composer:latest \
    bash -c "laravel new example-app"'

alias laravel="composer create-project laravel/laravel --prefer-dist"
alias ng="npx @angular/cli@latest"
alias nx="npx nx"
alias cdktf="npx cdktf-cli@latest"
alias ncu="npx npm-check-updates"
alias vue="npx @vue/cli"
alias pm2="npx pm2"
alias yarn="npx yarn"
