#!/usr/bin/env bash
# macOS cache cleaner — safe tier by default, --deep adds docker image prune -a.
# Usage: cleanup.sh [--dry-run] [--deep]
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

# du -sh or "-" if path missing
size_of() { [ -e "$1" ] && du -sh "$1" 2>/dev/null | cut -f1 || echo "-"; }

# rm -rf a path; prints action + size; silently skips missing dirs
clean_path() {
  local p="$1" label="${2:-$1}"
  [ -e "$p" ] || return 0
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  [dry] %-55s %s\n" "$label" "$(size_of "$p")"
  else
    printf "  [rm]  %-55s %s\n" "$label" "$(size_of "$p")"
    rm -rf "$p"
  fi
}

# run a prune command if its binary exists; docker ones only if daemon is up
run_cmd() {
  local bin="$1"; shift
  command -v "$bin" >/dev/null 2>&1 || return 0
  if [ "$bin" = "docker" ] && ! docker info >/dev/null 2>&1; then
    echo "  [skip] docker daemon not running"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf "  [dry] %s\n" "$bin $*"
  else
    printf "  [run] %s\n" "$bin $*"
    "$bin" "$@" 2>/dev/null
  fi
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

echo "docker:"
run_cmd docker builder prune -f
run_cmd docker system prune -f
[ "$DEEP" -eq 1 ] && run_cmd docker image prune -a -f
[ "$DRY_RUN" -eq 1 ] && [ "$DEEP" -eq 0 ] && echo "  [dry] (skipped: docker image prune -a — needs --deep)"

echo "package managers:"
run_cmd npm cache clean --force
clean_path "$HOME/.npm/_npx" "~/.npm/_npx"
run_cmd pnpm store prune
run_cmd pip3 cache purge
run_cmd yarn cache clean
clean_path "$HOME/Library/Caches/node-gyp" "~/Library/Caches/node-gyp"
run_cmd go clean -modcache

echo "app caches:"
clean_path "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt" "VSCode ShipIt"
clean_path "$HOME/Library/Caches/com.stablyai.orca.ShipIt" "Orca ShipIt"
clean_path "$HOME/Library/Caches/orca-updater" "orca-updater"
clean_path "$HOME/.cache/codex-runtimes" "~/.cache/codex-runtimes"
clean_path "$HOME/Library/Caches/com.openai.codex/org.sparkle-project.Sparkle" "Codex Sparkle"
clean_path "$HOME/Library/Application Support/stremio-server/stremio-cache" "stremio-cache"
clean_jetbrains

echo
if [ "$DRY_RUN" -eq 0 ]; then
  echo "disk after:  $(df_line)"
fi
echo "done."
