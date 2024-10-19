# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

mcd() {
    mkdir "$@" 2> >(sed s/mkdir/mcd/ 1>&2) && cd "$_"
}

skgrep() {
  local dir
  if [ -z "$1" ]; then
    dir="."
  else
    dir="$1"
  fi
  sk --ansi \
    --interactive --cmd "grep --recursive --binary-files=without-match --color=always --line-number '{}' $dir" \
    --delimiter : \
    --preview "bat --color=always --style=plain --line-range=:500 {1} --highlight-line {2}"
}

alias pwsh="/mnt/c/Program\ Files/PowerShell/7/pwsh.exe"
if command -v vim >/dev/null; then
  export GIT_EDITOR=$(command -v vim)
  export EDITOR=$(command -v vim)
fi

export PROMPT_COMMAND='echo -en "\e[3 q""\n"'

if command -v git >/dev/null; then
  export GIT_PS1_SHOWDIRTYSTATE=1
  export GIT_PS1_SHOWSTASHSTATE=1
  export GIT_PS1_SHOWUNTRACKEDFILES=1
  export GIT_PS1_SHOWCOLORHINTS=1
  export GIT_PS1_SHOWUPSTREAM=auto
  export PS1=$(printf '%s %s\n%s ' \
    '\[\e[1;36m\]\w\[\e[m\]' \
    '$(__git_ps1 "(%s)")' \
    '\[\e[1;34m\]>\[\e[m\]' \
  )
fi

if command -v pwsh 2>&1 >/dev/null; then
  # Remove CR using NoNewLine option to avoid moving cursor to the beginning of the line
  export WINHOME=$(wslpath $(pwsh -NoLogo -NoProfile -c \
    'Write-Host -NoNewLine $env:USERPROFILE'))
      export PATH="$PATH:$WINHOME/AppData/Local/Programs/Microsoft VS Code/bin"
fi

p=$(
IFS=','
a=(
  "$PATH",
  "$HOME/go/bin",
  "$HOME/.config/elixir/ls/rel",
  "$HOME/.local/bin",
  ""
  )
  echo ${a[@]}
)
export PATH=$(echo $p | tr ' ' ':')

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

# if [ "$color_prompt" = yes ]; then
#     PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# else
#     PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
# fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
#    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if command -v mise > /dev/null; then
  eval "$(mise activate --shims bash)"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

complete -C ~/go/bin/gocomplete go
# Check if pam_systemd has failed to set XDG_RUNTIME_DIR
if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR="/run/user/$UID"
fi

# Ensure the directory exists for zellij to start properly
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
  sudo mkdir -p "$XDG_RUNTIME_DIR"
  sudo chown "$UID:$UID" "$XDG_RUNTIME_DIR"
  ln -sf /mnt/wslg/runtime-dir/wayland-0 /run/user/$UID
fi

if command -v mise > /dev/null; then
  eval "$(mise activate bash)"
fi

stty -ixon
export PATH="$PATH:/opt/mssql-tools18/bin"
. ~/z/z.sh

if command -v sk >/dev/null; then
  export SKIM_DEFAULT_COMMAND="git ls-tree -r --name-only HEAD || find . -type f"
  export SKIM_DEFAULT_OPTIONS="
  --bind=ctrl-y:preview-up,ctrl-e:preview-down,ctrl-b:preview-page-up,ctrl-f:preview-page-down
  --bind=ctrl-a:toggle-all,ctrl-alt-p:toggle-preview
  --multi
  "
  if command -v bat >/dev/null; then
    SKIM_DEFAULT_OPTIONS+="--preview 'bat --color=always --style=plain --line-range=:500 {1}'"
  else
    SKIM_DEFAULT_OPTIONS+="--preview 'head --lines=500 {1}'"
  fi
fi

if command -v bat >/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  ghelp() {
    "$@" --help 2>&1 | bat -l help -p
  }
  _ghelp(){
    local cur prev
    _get_comp_words_by_ref -n : cur prev
    if [ "$prev" == "ghelp" ] && [ "$cur" != "" ]; then
      COMPREPLY=($(compgen -c "$cur"))
    fi
  }
  complete -F _ghelp ghelp
fi
