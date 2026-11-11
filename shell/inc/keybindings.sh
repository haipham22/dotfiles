# Alt+<key> word-wise editing, works across iTerm2 (macOS), GNOME Terminal (Linux),
# Windows Terminal / WSL. Bind every known escape sequence; unused binds are no-ops.
bindkey -e

# Alt+Backspace / Alt+Delete: delete word backward / forward
bindkey '^[^?'   backward-kill-word   # ESC + DEL (most terminals)
bindkey '^[[3;3~' kill-word           # Alt+Delete forward

# Alt+Left / Alt+Right: jump word backward / forward
bindkey '^[[1;3D' backward-word       # xterm-style (GNOME, Windows Terminal, iTerm2)
bindkey '^[[1;3C' forward-word
bindkey '^[b'     backward-word       # iTerm2 "Option as Esc+"
bindkey '^[f'     forward-word
bindkey '^[O3D'   backward-word       # rxvt-style
bindkey '^[O3C'   forward-word

# TUIs that exit without cleanup (killed, crashed) leave SGR mouse-tracking on,
# so moving the mouse spews ESC[<...M garbage at the prompt. Reset at every prompt.
terminal_disable_mouse() { printf '\e[?1000l\e[?1002l\e[?1003l\e[?1015l\e[?1006l' }
precmd_functions+=(terminal_disable_mouse)
