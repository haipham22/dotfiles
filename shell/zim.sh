#!/bin/zsh

ZIM_HOME=~/.zim
ZIM_CONFIG_FILE=~/.config/zsh/zimrc

# Re-sourcing runs the completion module's compinit wrapper twice -> warning noise
[[ -n ${_ZIM_INITIALIZED} ]] && return

# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Install missing modules and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi

# Reset completion state before re-init: zimfw warns if `_comps` is set
# (already initialized) and redefines `compinit` to a warning on later loads,
# so re-sourcing ~/.zshrc would print noise each time.
unset _comps 2>/dev/null
(( $+functions[compinit] )) && { unfunction compinit; autoload -Uz compinit }

# Initialize modules.
source ${ZIM_HOME}/init.zsh
_ZIM_INITIALIZED=1

# zim's input module bakes ${widgets[zle-line-init]#user:} into the
# _start_application_mode body. In Orca-spawned terminals that captured name is
# Orca's transient wrapper fn, which Orca unfunctions at the first prompt ->
# "zsh: command not found" spam on every prompt afterwards. The captured fn's
# work is already done by then, so keep only the smkx call. In plain terminals
# the captured name is empty, so this is a no-op there.
if (( ${+functions[_start_application_mode]} )); then
  functions[_start_application_mode]=$'echoti smkx'
fi

# zmodule sindresorhus/pure --source async.zsh
# zmodule romkatv/powerlevel10k --use degit