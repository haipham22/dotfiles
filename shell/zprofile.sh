# mise shims for non-interactive sessions (IDE, scripts, GUI apps).
# Sourced from ~/.zprofile (login shells). Full path: ~/.local/bin may not be
# on PATH yet at login. Per https://mise.jdx.dev/dev-tools/shims.html
# interactive sessions use PATH activation in zsh.sh, which removes shims from PATH.
for _mise in "$HOME/.local/bin/mise" /opt/homebrew/bin/mise /usr/local/bin/mise; do
  [[ -x "$_mise" ]] && eval "$("$_mise" activate zsh --shims)" && break
done
