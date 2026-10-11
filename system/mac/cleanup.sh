#!/usr/bin/env bash
# macOS cache cleaner — safe tier by default, --deep adds docker image prune -a.
# Usage: cleanup.sh [--dry-run] [--deep]
# Docker prunes always ask for confirmation (default No); non-TTY skips them.
# Never touches: docker volumes, ZaloData, browser profiles, ~/.gradle, ~/Downloads.
set -u

DRY_RUN=0
DEEP=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --deep)    DEEP=1 ;;
    *) echo "unknown arg: $arg (use --dry-run, --deep)"; exit 1 ;;
  esac
done

LOG=()  # rows: "size<TAB>label", printed as summary table at the end

# du -sh or "-" if path missing
size_of() { [ -e "$1" ] && du -sh "$1" 2>/dev/null | cut -f1 || echo "-"; }

log_row() { LOG+=("${1//--/-}$(printf '\t')$2"); }

print_table() {
  echo
  echo "Cleaned items:"
  printf "%-10s  %s\n" "SIZE" "ITEM"
  printf "%-10s  %s\n" "----" "----"
  if [ ${#LOG[@]} -eq 0 ]; then
    printf "%-10s  %s\n" "0B" "(nothing to clean)"
    return
  fi
  local row size label
  for row in ${LOG[@]+"${LOG[@]}"}; do
    size=${row%%$'\t'*}
    label=${row#*$'\t'}
    printf "%-10s  %s\n" "$size" "$label"
  done
}

# rm -rf a path; logs action + size; silently skips missing dirs
clean_path() {
  local p="$1" label="${2:-$1}" sz
  [ -e "$p" ] || return 0
  sz=$(size_of "$p")
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  [dry] %-55s %s\n" "$label" "$sz"
  else
    printf "  [rm]  %-55s %s\n" "$label" "$sz"
    rm -rf "$p"
  fi
  log_row "$sz" "$label"
}

# run a prune command if its binary exists; docker ones only if daemon is up
run_cmd() {
  local bin="$1"; shift
  command -v "$bin" >/dev/null 2>&1 || return 1
  if [ "$bin" = "docker" ] && ! docker info >/dev/null 2>&1; then
    echo "  [skip] docker daemon not running"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  [dry] %s\n" "$bin $*"
    return 0
  fi
  printf "  [run] %s\n" "$bin $*"
  "$bin" "$@" 2>/dev/null
}

# run a docker prune, parse its reclaimed-space line into the summary table
docker_prune() {
  local out reclaimed
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  [dry] docker %s\n" "$*"
    return 0
  fi
  printf "  [run] docker %s\n" "$*"
  out=$(docker "$@" 2>/dev/null)
  reclaimed=$(printf '%s' "$out" | grep -o 'reclaimed space: .*' | awk '{print $3" "$4}')
  log_row "${reclaimed:--}" "docker $*"
}

# ask before docker prunes; default No; non-TTY = skip
confirm_docker() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  if [ ! -t 0 ]; then
    echo "  [skip] no TTY — docker prunes need interactive confirmation"
    return 1
  fi
  local ans
  printf "  docker prunes (listed above) — run them? [y/N] "
  read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

# JetBrains caches: keep newest IntelliJIdea version dir, delete older ones
clean_jetbrains() {
  local base="$HOME/Library/Caches/JetBrains/IntelliJIdea"
  [ -d "$base" ] || return 0
  local newest
  newest=$(ls "$base" 2>/dev/null | sort -V | tail -1)
  [ -n "$newest" ] || return 0
  echo "  keeping: IntelliJIdea/$newest"
  local d
  for d in "$base"/*; do
    [ "$(basename "$d")" = "$newest" ] || clean_path "$d" "JetBrains/IntelliJIdea/$(basename "$d") (old)"
  done
}

df_line() { df -h / | awk 'NR==2 {print $3" used / "$2", "$5}'; }

echo "🧹 macOS cleanup $( [ "$DEEP" -eq 1 ] && echo '(deep)' )$( [ "$DRY_RUN" -eq 1 ] && echo ' — DRY RUN' )"
echo "disk before: $(df_line)"
echo

echo "docker (asks before deleting):"
if confirm_docker; then
  docker_prune builder prune -f
  docker_prune system prune -f
  if [ "$DEEP" -eq 1 ]; then
    docker_prune image prune -a -f
  elif [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry] (skipped: docker image prune -a — needs --deep)"
  fi
else
  echo "  [skip] docker prunes not confirmed"
fi

echo "package managers:"
run_cmd npm cache clean --force && log_row "-" "npm cache clean"
clean_path "$HOME/.npm/_npx" "~/.npm/_npx"
run_cmd pnpm store prune && log_row "-" "pnpm store prune"
run_cmd pip3 cache purge && log_row "-" "pip cache purge"
run_cmd yarn cache clean && log_row "-" "yarn cache clean"
clean_path "$HOME/Library/Caches/node-gyp" "~/Library/Caches/node-gyp"
run_cmd go clean -modcache && log_row "-" "go modcache"

echo "app caches:"
clean_path "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt" "VSCode ShipIt"
clean_path "$HOME/Library/Caches/com.stablyai.orca.ShipIt" "Orca ShipIt"
clean_path "$HOME/Library/Caches/orca-updater" "orca-updater"
clean_path "$HOME/.cache/codex-runtimes" "~/.cache/codex-runtimes"
clean_path "$HOME/Library/Caches/com.openai.codex/org.sparkle-project.Sparkle" "Codex Sparkle"
clean_path "$HOME/Library/Application Support/stremio-server/stremio-cache" "stremio-cache"
clean_jetbrains

print_table
echo
if [ "$DRY_RUN" -eq 0 ]; then
  echo "disk after:  $(df_line)"
fi
echo "done."
