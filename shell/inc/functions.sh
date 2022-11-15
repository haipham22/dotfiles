function git_clean_local() {
  echo "Delete local branch except $1"
  git branch | grep -v "$1" | xargs git branch -D
}