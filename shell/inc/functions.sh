function git_clean_branch() {
  echo "Delete local branch except $1"
  git branch | grep -v "$1" | xargs git branch -D
}

function git_empty_commit() {
  git commit --allow-empty -m "Empty-Commit" && git push
}

function pn_version() {
  pnpm env use --global $1
}