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

# Kill process(es) listening on specific port(s)
# Usage: killport 3001              # Kill single port
#        killport 3000-3005        # Kill port range
#        killport 3000 8080 9000   # Kill multiple ports
function killport() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: killport <port> or <start-end> or <port1> <port2> ..."
    echo "Example: killport 3001"
    echo "         killport 3000-3005"
    echo "         killport 3000 8080 9000"
    return 1
  fi

  local ports_to_kill=()

  # Parse arguments: handle single ports and ranges
  for arg in "$@"; do
    if [[ "$arg" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      # Port range (e.g., 3000-3005)
      local start="${match[1]}"
      local end="${match[2]}"

      if [[ $start -gt $end ]]; then
        echo "❌ Invalid range: $arg (start > end)"
        continue
      fi

      # Generate port list from range
      for ((port = start; port <= end; port++)); do
        ports_to_kill+=("$port")
      done
    elif [[ "$arg" =~ ^[0-9]+$ ]]; then
      # Single port
      ports_to_kill+=("$arg")
    else
      echo "⚠️  Skipping invalid port: $arg"
    fi
  done

  if [[ ${#ports_to_kill[@]} -eq 0 ]]; then
    echo "❌ No valid ports specified"
    return 1
  fi

  local killed_count=0
  local not_found_count=0

  # Kill processes on each port
  for port in "${ports_to_kill[@]}"; do
    # Use lsof to find process listening on the port (macOS compatible)
    local pid=$(lsof -ti ":$port" 2>/dev/null)

    if [[ -n "$pid" ]]; then
      # Get command name for better feedback
      local cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
      echo "🔪 Killing $cmd (PID: $pid) on port $port"
      kill -9 "$pid" 2>/dev/null && ((killed_count++))
    else
      echo "⚠️  No process found on port $port"
      ((not_found_count++))
    fi
  done

  # Summary
  echo
  if [[ $killed_count -gt 0 ]]; then
    echo "✅ Killed $killed_count process(es)"
  fi
  if [[ $not_found_count -gt 0 ]]; then
    echo "ℹ️  $not_found_count port(s) had no process"
  fi
}

# Alias for quick fix
alias fix-zim='fix_zim_completion'

# Install .deb packages from URL (Linux only)
if [[ "$(uname)" == "Linux" ]]; then
  function install-deb() {
    "$DOTFILES_DIR/shell/inc/install-deb.sh" "$@"
  }
fi