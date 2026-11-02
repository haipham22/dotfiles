#!/usr/bin/env bash
# macOS cache cleaner — interactive menu by default, --all skips the menu.
# Usage: cleanup.sh [--dry-run] [--deep] [--all] [--zalo]
#   --dry-run  preview every category, delete nothing
#   --deep     add browser caches (only when browser closed) + docker image prune -a
#   --all      run every category without the menu
#   --zalo     add Zalo cache/media category to the menu (media asks confirm)
# Docker prunes always ask for confirmation (default No).
# Only touches ZaloData with --zalo (media re-downloads on view in Zalo).
# Never touches: browser profile data, ~/.gradle, ~/Downloads.
set -u

DRY_RUN=0
DEEP=0
ALL=0
ZALO=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --deep)    DEEP=1 ;;
    --all|-y)  ALL=1 ;;
    --zalo)    ZALO=1 ;;
    *) echo "unknown arg: $arg (use --dry-run, --deep, --all, --zalo)"; exit 1 ;;
  esac
done

LOG=()  # rows: "size<TAB>label", printed as summary table at the end

# du -sh or "-" if path missing
size_of() { [ -e "$1" ] && du -sh "$1" 2>/dev/null | cut -f1 || echo "-"; }

# combined du -sh of several paths (missing ones ignored)
sum_size() { du -sch "$@" 2>/dev/null | tail -1 | cut -f1; }

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

# shared prompt for opt-in destructive steps (docker prunes, Zalo media)
confirm_yn() {
  local msg="$1"
  if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
  if [ ! -t 0 ]; then
    echo "  [skip] no TTY — needs interactive confirmation"
    return 1
  fi
  local ans
  printf "  %s [y/N] " "$msg"
  read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

confirm_docker() {
  confirm_yn "docker prunes (listed above) — run them?"
}

# versioned product caches: keep newest version dir, delete older ones
clean_old_versions() {
  local base="$1" label="$2" pattern="${3:-*}"
  [ -d "$base" ] || return 0
  local newest d
  newest=$(cd "$base" 2>/dev/null && ls -d $pattern 2>/dev/null | sort -V | tail -1)
  [ -n "$newest" ] || return 0
  echo "  keeping: $label/$newest"
  for d in "$base"/$pattern; do
    [ "$(basename "$d")" = "$newest" ] || clean_path "$d" "$label/$(basename "$d") (old)"
  done
}

# size in KB of old version dirs only (what would actually be freed)
old_versions_kb() {
  local base="$1" pattern="${2:-*}" newest total=0 sz d
  newest=$(cd "$base" 2>/dev/null && ls -d $pattern 2>/dev/null | sort -V | tail -1)
  [ -n "$newest" ] || { echo 0; return; }
  for d in "$base"/$pattern; do
    [ "$(basename "$d")" = "$newest" ] && continue
    sz=$(du -sk "$d" 2>/dev/null | cut -f1)
    total=$((total + ${sz:-0}))
  done
  echo "$total"
}

human_mb() {
  if [ "$1" -ge 1024 ]; then
    echo "$(( $1 / 1024 )).$(( ($1 % 1024) * 10 / 1024 ))GB"
  else
    echo "${1}MB"
  fi
}

old_versions_size() { human_mb $(( $(old_versions_kb "$1" "${2:-*}") / 1024 )); }

# playwright stores one dir per browser build (chromium-1234); old builds pile up
clean_playwright() {
  local base="$HOME/Library/Caches/ms-playwright"
  [ -d "$base" ] || return 0
  local p newest d
  for p in $(ls "$base" 2>/dev/null | sed -E 's/-[0-9]+$//' | sort -u); do
    newest=$(ls "$base" | grep "^$p-" | sort -t- -k2 -n | tail -1)
    [ -n "$newest" ] || continue
    echo "  keeping: ms-playwright/$newest"
    for d in "$base/$p"-*; do
      [ "$(basename "$d")" = "$newest" ] || clean_path "$d" "ms-playwright/$(basename "$d") (old)"
    done
  done
}

# sparkle updater downloads pile up across every app using the framework
clean_sparkle() {
  local d
  for d in "$HOME/Library/Caches/"*/org.sparkle-project.Sparkle; do
    [ -e "$d" ] || continue
    clean_path "$d" "$(basename "$(dirname "$d")")/Sparkle updates"
  done
}

clean_browser_cache() {
  local app="$1" p="$2"
  if pgrep -xq "$app"; then
    echo "  [skip] $app is running"
    return 0
  fi
  clean_path "$p" "$app cache"
}

# ---- categories ----

run_docker() {
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
}

run_pkg() {
  echo "package managers:"
  run_cmd npm cache clean --force && log_row "-" "npm cache clean"
  clean_path "$HOME/.npm/_npx" "~/.npm/_npx"
  run_cmd pnpm store prune && log_row "-" "pnpm store prune"
  run_cmd pip3 cache purge && log_row "-" "pip cache purge"
  run_cmd yarn cache clean && log_row "-" "yarn cache clean"
  clean_path "$HOME/Library/Caches/node-gyp" "~/Library/Caches/node-gyp"
  run_cmd brew cleanup --prune=all -s && log_row "-" "brew cleanup --prune=all -s"
  run_cmd go clean -modcache && log_row "-" "go modcache"
  run_cmd go clean -cache && log_row "-" "go build cache"
}

run_apps() {
  echo "app caches:"
  clean_path "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt" "VSCode ShipIt"
  clean_path "$HOME/Library/Caches/com.stablyai.orca.ShipIt" "Orca ShipIt"
  clean_path "$HOME/Library/Caches/orca-updater" "orca-updater"
  clean_path "$HOME/.cache/codex-runtimes" "~/.cache/codex-runtimes"
  clean_path "$HOME/Library/Caches/Codex" "Codex cache"
  clean_path "$HOME/Library/Application Support/stremio-server/stremio-cache" "stremio-cache"
  clean_sparkle
}

run_ide() {
  echo "old IDE versions (keeps newest of each):"
  clean_old_versions "$HOME/Library/Caches/JetBrains/IntelliJIdea" "JetBrains/IntelliJIdea"
  clean_old_versions "$HOME/Library/Caches/Google" "Google/AndroidStudio" "AndroidStudio*"
  clean_old_versions "$HOME/Library/Application Support/JetBrains" "AppSupport/JetBrains/IntelliJIdea" "IntelliJIdea*"
  clean_old_versions "$HOME/Library/Application Support/Google" "AppSupport/Google/AndroidStudio" "AndroidStudio*"
}

run_playwright() {
  echo "playwright:"
  clean_playwright
}

run_browser() {
  echo "browser caches:"
  if [ "$DEEP" -eq 1 ]; then
    clean_browser_cache "Google Chrome" "$HOME/Library/Caches/Google/Chrome"
    clean_browser_cache "Microsoft Edge" "$HOME/Library/Caches/Microsoft Edge"
    if ! pgrep -xq "Google Chrome"; then
      clean_path "$HOME/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel" \
        "Chrome on-device AI model (re-downloads unless disabled in chrome://flags)"
    fi
  else
    echo "  [skip] needs --deep"
  fi
}

run_xcode() {
  echo "xcode:"
  run_cmd xcrun simctl delete unavailable && log_row "-" "simulators (unavailable runtimes)"
  clean_path "$HOME/Library/Developer/CoreSimulator/Caches" "CoreSimulator caches"
}

run_zalo() {
  echo "zalo:"
  if pgrep -xq Zalo; then
    echo "  [skip] Zalo is running"
    return 0
  fi
  local base="$HOME/Library/Application Support/ZaloData"
  clean_path "$base/Cache" "Zalo cache"
  clean_path "$base/logs" "Zalo logs"
  if [ -d "$base/media" ]; then
    if confirm_yn "delete Zalo media ($(size_of "$base/media"))? chats re-download media on view; Database untouched"; then
      clean_path "$base/media" "Zalo media"
    else
      echo "  [skip] Zalo media kept"
    fi
  fi
}

# ---- menu ----

MENU_ORDER="pkg apps ide xcode playwright browser docker"
[ "$ZALO" -eq 1 ] && MENU_ORDER="$MENU_ORDER zalo"

menu_desc() {
  case "$1" in
    pkg)       echo "npm, pnpm, pip, yarn, brew, go caches" ;;
    apps)      echo "ShipIt, Sparkle updates, Codex, stremio" ;;
    ide)       echo "old JetBrains + AndroidStudio (caches + settings)" ;;
    xcode)     echo "simulators for unavailable runtimes" ;;
    playwright) echo "old browser builds, keeps newest" ;;
    browser)   echo "Chrome/Edge cache + Chrome AI model, needs --deep" ;;
    docker)    echo "builder/system prune, asks confirm; -a needs --deep" ;;
    zalo)      echo "Zalo cache/logs + media (asks confirm), needs --zalo" ;;
  esac
}

menu_size() {
  case "$1" in
    pkg)        sum_size "$HOME/.npm" "$HOME/Library/Caches/node-gyp" "$HOME/Library/Caches/pip" "$HOME/Library/Caches/Homebrew" "$HOME/Library/Caches/go-build" ;;
    apps)       sum_size "$HOME/Library/Caches/com.microsoft.VSCode.ShipIt" "$HOME/Library/Caches/com.stablyai.orca.ShipIt" "$HOME/Library/Caches/orca-updater" "$HOME/.cache/codex-runtimes" "$HOME/Library/Caches/Codex" "$HOME/Library/Caches/"*/org.sparkle-project.Sparkle ;;
    ide)        local t=0 kb
                kb=$(old_versions_kb "$HOME/Library/Application Support/JetBrains" "IntelliJIdea*"); t=$((t + kb))
                kb=$(old_versions_kb "$HOME/Library/Application Support/Google" "AndroidStudio*"); t=$((t + kb))
                kb=$(old_versions_kb "$HOME/Library/Caches/Google" "AndroidStudio*"); t=$((t + kb))
                echo "$(human_mb $((t / 1024)))" ;;
    xcode)      sum_size "$HOME/Library/Developer/CoreSimulator" ;;
    playwright) sum_size "$HOME/Library/Caches/ms-playwright" ;;
    browser)    sum_size "$HOME/Library/Caches/Google/Chrome" "$HOME/Library/Caches/Microsoft Edge" "$HOME/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel" ;;
    docker)     echo "-" ;;
    zalo)       sum_size "$HOME/Library/Application Support/ZaloData/Cache" "$HOME/Library/Application Support/ZaloData/logs" "$HOME/Library/Application Support/ZaloData/media" ;;
  esac
}

print_menu() {
  echo "🧹 macOS cleanup$( [ "$DEEP" -eq 1 ] && echo ' (deep)' )$( [ "$DRY_RUN" -eq 1 ] && echo ' — DRY RUN' )"
  echo "disk before: $(df_line)"
  echo
  local i=0 name
  for name in $MENU_ORDER; do
    i=$((i + 1))
    printf "  %d) %-10s %8s   %s\n" "$i" "$name" "$(menu_size "$name")" "$(menu_desc "$name")"
  done
}

name_at() {
  local i=0 n
  for n in $MENU_ORDER; do
    i=$((i + 1))
    [ "$i" -eq "$1" ] && { echo "$n"; return; }
  done
}

# prints selected category names, space-separated; empty = quit
pick_categories() {
  if [ "$ALL" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    echo "$MENU_ORDER"
    return
  fi
  if [ ! -t 0 ]; then
    echo "$MENU_ORDER"
    return
  fi
  print_menu >&2
  printf "\nchoose numbers (e.g. 1 3 5), 'all', or 'q' to quit: " >&2
  local ans tok n out=""
  if ! read -r ans; then
    echo "  (EOF — quit)" >&2
    return
  fi
  [ -z "$ans" ] && return
  for tok in $ans; do
    case "$tok" in
      all|a)      echo "$MENU_ORDER"; return ;;
      q|quit)     return ;;
      *[!0-9]*)   echo "  (ignore: $tok)" >&2 ;;
      *)          n=$(name_at "$tok") && out="$out $n" ;;
    esac
  done
  echo "$out"
}

df_line() { df -h / | awk 'NR==2 {print $3" used / "$2", "$5}'; }

SELECTED=$(pick_categories)
if [ -z "${SELECTED// /}" ]; then
  echo "nothing selected. bye."
  exit 0
fi

for name in $SELECTED; do
  echo
  case "$name" in
    pkg)       run_pkg ;;
    apps)      run_apps ;;
    ide)       run_ide ;;
    xcode)     run_xcode ;;
    playwright) run_playwright ;;
    browser)   run_browser ;;
    docker)    run_docker ;;
    zalo)      run_zalo ;;
  esac
done

print_table
echo
if [ "$DRY_RUN" -eq 0 ]; then
  echo "disk after:  $(df_line)"
fi
echo "done."
