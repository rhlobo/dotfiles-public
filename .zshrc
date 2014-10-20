# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"
# ZSH_THEME="bira"
# ZSH_THEME="nebirhos"
# ZSH_THEME="nalpartym

# Set to this to use case-sensitive completion
CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# # VCS as dirty. This makes repository status check for large repositories much,
# # much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# # Uncomment following line if you want to  shown in the command execution time stamp 
# # in the history command output. The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
#plugins=(autopep8 bower bundler cabal cake cap catimg celery command-not-found composer coffee compleat dircycle fabric gem gpg-agent git github mvn npm per-directory-history pep8 pip python ruby rvm ssh-agent sublime supervisor taskwarrior vagrant virtualenvwrapper)
plugins=(autopep8 catimg command-not-found compleat docker gem git gitfast github pep8 pip python ruby rvm supervisor taskwarrior vagrant vi-mode)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...

# Tab completion from both ends
#setopt completeinword

# Tab completion should be case-insensitive.
#zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Better completion for killall.
zstyle ':completion:*:killall:*' command 'ps -u $USER -o cmd'

# Changes the definition of "word", e.g. with ^W.
autoload select-word-style
select-word-style shell

# Colors for ls
if [[ -x "`whence -p dircolors`" ]]; then
  eval `dircolors`
  alias ls='ls -F --color=auto'
else
  alias ls='ls -F'
fi

# One history for all open shells; store 10,000 entires. 
# This makes this into a useful memory aid to find the commands you used last time. 
# Use Alt-P (find command that starts like this) and ^R (search in history) liberally.
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="${HOME}/.zhistory-${HOST}"
setopt incappendhistory
#setopt sharehistory
setopt extendedhistory

# Enables all sorts of extended globbing, such as ls */.txt (find all text files), ls -d *(D) (show all files including those starting with "."). To find out more, go to man zshexpn, section "FILENAME GENERATION".
setopt extendedglob
unsetopt caseglob

# Display CPU usage stats for commands taking more than 10 seconds
REPORTTIME=10

# Do not kill background jobs on shell exit
setopt no_hup

# Disable auto correct
unsetopt correct_all

# List ambiguous files on completion (don't fill in first file)
#setopt AUTO_LIST
#setopt BASH_AUTO_LIST
#setopt LIST_AMBIGUOUS
#unsetopt LIST_TYPES

# Disables 'JOBS RUNNING' warning
# unsetopt monitor

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

### VI MODE
# Resources:
#   http://dougblack.io/words/zsh-vi-mode.html

# Activating vi-mode
bindkey -v

# ESC timeout (2 = 200 milis)
export KEYTIMEOUT=2

# Use vim cli mode
bindkey '^P' up-history
bindkey '^N' down-history

# backspace and ^h working even after
# returning from command mode
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# ctrl-w removed word backwards
bindkey '^w' backward-kill-word

# ctrl-r starts searching history backward
bindkey '^r' history-incremental-search-backward

# ctrl+u delete entire line
bindkey "^U" kill-line

# home and end keys
bindkey $terminfo[khome] vi-beginning-of-line
bindkey $terminfo[kend] vi-end-of-line

# delete key
bindkey '^[[3~' delete-char

### PROMPT
# Functions that update prompt on new line or on keymap change
function zle-line-init zle-keymap-select {
    # vi mode mode prompt var (NORMAL MODE, INSERT MODE SHOWS NOTHING)
    VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]% %{$reset_color%}"

    BATTERY=$(upower -i `upower -e | grep battery` | grep percentage | awk '{print $2}')
    BATTERY_PROMPT="%{$fg_bold[white]%} ${BATTERY}%% %{$reset_color%}"

    # right prompt, showing viMode, host, time, etc
    RPROMPT='${BATTERY_PROMPT} ${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/} %{$fg[blue]%}${HOST} %{$fg_bold[cyan]%}%t%{$reset_color%}'

    # Redraws prompt
    zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select

### ---
# Calling bash personal configurations
[ -f ~/.shell_extension ] && . ~/.shell_extension

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
