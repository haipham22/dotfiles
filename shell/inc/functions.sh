function git_clean_branch() {
  echo "Delete local branch except $1"
  git branch | grep -v "$1" | xargs git branch -D
}

function git_empty_commit() {
  git commit --allow-empty -m "Empty-Commit" && git push
}

function node_ver() {
  pnpm env use --global $1
}

function node_ls() {
  if [ $# -eq 0 ]; then
      pnpm env list --remote
  else 
      pnpm env list --remote | grep "$1" 
  fi
}

function clean_ds() {
  find . -name ".DS_Store" -print -delete
}

function short_commit() {
  git rev-parse --short $1
}