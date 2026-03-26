function git_clean_branch() {
  echo "Delete local branch except $1"
  git branch | grep -v "$1" | xargs git branch -D
}

function git_empty_commit() {
  git commit --allow-empty -m "Empty-Commit" && git push
}

function clean_ds() {
  find . -name ".DS_Store" -print -delete
}

function short_commit() {
  git rev-parse --short $1
}

# Diagnose and fix zimfw completion issues
function fix_zim_completion() {
  echo "🔍 Diagnosing zimfw completion issues..."
  echo

  # Check if .zshrc sources zsh.sh
  if ! grep -q "source.*dotfiles/shell/zsh.sh" ~/.zshrc 2>/dev/null; then
    echo "❌ dotfiles/shell/zsh.sh not found in ~/.zshrc"
    return 1
  fi

  # Check for duplicate starship init
  local starship_count=$(grep -c "starship init zsh" ~/.zshrc 2>/dev/null | tr -d '\n' || echo 0)
  if [ "$starship_count" -gt 1 ]; then
    echo "⚠️  Found $starship_count 'starship init zsh' calls in ~/.zshrc"
    echo "   Remove duplicates from ~/.zshrc"
  fi

  # Check load order in zsh.sh
  local zsh_sh="$DOTFILES_DIR/shell/zsh.sh"
  if [ -f "$zsh_sh" ]; then
    local zim_line=$(grep -n "source.*zim.sh" "$zsh_sh" | cut -d: -f1)
    local zoxide_line=$(grep -n "zoxide init" "$zsh_sh" | cut -d: -f1)

    if [ -n "$zim_line" ] && [ -n "$zoxide_line" ]; then
      if [ "$zim_line" -gt "$zoxide_line" ]; then
        echo "❌ zimfw loads AFTER zoxide (should load first)"
        echo "   zim.sh line: $zim_line, zoxide line: $zoxide_line"
        return 1
      else
        echo "✅ zimfw loads before zoxide (correct order)"
      fi
    fi
  fi

  # Check .zshenv for mise
  if grep -q "mise activate" ~/.zshenv 2>/dev/null; then
    echo "⚠️  mise activation found in ~/.zshenv"
    echo "   This may call compinit before zimfw"
  fi

  echo
  echo "🔧 Attempting automatic fixes..."

  # Clean zcompdump
  echo "   Cleaning .zcompdump files..."
  rm -f ~/.zcompdump*(N) 2>/dev/null || true

  # Reinstall zimfw
  if command -v zimfw &>/dev/null; then
    echo "   Reinstalling zimfw..."
    zimfw install
  fi

  echo
  echo "✅ Fix complete. Restart your shell: exec zsh"
}

# Alias for quick fix
alias fix-zim='fix_zim_completion'