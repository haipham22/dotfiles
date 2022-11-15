function git_clean_branch() {
  echo "Delete local branch except $1"
  git branch | grep -v "$1" | xargs git branch -D
}