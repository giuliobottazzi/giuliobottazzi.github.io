#file: ~/.zsrc
#author: Giulio Bottazzi
#last modified: Mon Jun  8 2009


#------------------------------------------------
# List colors -----------------------------------

#to have colored lists
eval `dircolors ~/.dircolors`

#alias ls="ls --color=auto"
#to have color also in less/more
alias ls="ls --color"
alias less="less -R"
#------------------------------------------------


#------------------------------------------------
# Completion ------------------------------------


# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list '' '' '' ''
zstyle ':completion:*' use-compctl false
zstyle :compinstall filename '/home/giulio/.zshrc'

#suggested by Gentoo guide
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'

#suggested by zsh portage installation
zstyle ':completion::complete:*' use-cache 1

autoload -Uz compinit
compinit
# End of lines added by compinstall
#------------------------------------------------

#------------------------------------------------
# Commands correction ---------------------------

#suggested by Gentoo guide
setopt correctall

#------------------------------------------------




#------------------------------------------------
#Prompt (console,xterm,screen..)-----------------


if [[ $TERM == (*xterm*|*rxvt*|(dt|k|E|a)term) ]]; then

#puth the path in windows title
#better to use precmd defined beelow
#chpwd() {
#    [[ -t 1 ]] || return
#change only the title
#    print -Pn "\e]2;%n@%m:%~\a"
#change the title and the icon-name
#    print -Pn "\e]0;%n@%m:%~\a"
#}

#set a "constant" prompt
PROMPT="%n@%m>"

#title and icon-name with current directory
precmd () {
    print -Pn "\e]0;%n@%m:%~\a"
}


elif [[ $TERM == screen* ]]; then

# if screen is in use modify the hardstatus (thanks to
# phil_g@pobox.com)

# to put the last command name if the command is still running or
preexec () {
    local CMD=`echo $1 | sed 's/^sudo //; s/ .*//; 2,$d'`
    echo -n "\ek$CMD\e\\"
}

# put the current directory
precmd () {
# %~ is $PWD where ~ is replaced if needed
#    print -Pn "\ek%~\e\\"
# %1/ is the last piece of $PWD
    print -Pn "\ek%1/\e\\"
#clear the hardstatus line
    print -Pn "\e_\e\\"
}

#set a "constant" prompt
PROMPT="%n@%m>"

#set the starting title and icon-name
print -Pn "\e]0;%n@%m\a"

else

# default prompt from zsh installation on gentoo
autoload -U promptinit
promptinit; prompt gentoo

fi

#------------------------------------------------


#------------------------------------------------
# Automatic file handling -----------------------

autoload -U zsh-mime-setup
zstyle ':mime:*' mailcap ~/.mailcap
zstyle ':mime:*' mime-types ~/.mime.types 
zsh-mime-setup

autoload -U pick-web-browser
alias -s html=pick-web-browser
alias -s htm=pick-web-browser

zstyle ':mime:*' x-browsers firefox opera
zstyle ':mime:*' tty-browsers lynx
#------------------------------------------------

#------------------------------------------------
# History ---------------------------------------

# The file to save the history in when an interactive shell exits.  If
# unset, the history is not saved.
HISTFILE=${HOME}/.zsh_history

# The maximum number of events stored in the internal history list.
HISTSIZE=1000
SAVEHIST=1000

# zsh sessions will append their history list to the history file,
# rather than overwrite it. Thus, multiple parallel zsh sessions will
# all have their history lists added to the history file, in the order
# they are killed.
#setopt APPEND_HISTORY

# new history lines are added to the $HISTFILE incrementally (as soon
# as they are entered), rather than waiting until the shell is killed.
#setopt INC_APPEND_HISTORY

# This option both imports new commands from the history file, and
# also causes your typed commands to be appended to the history file
setopt SHARE_HISTORY

# Remove superfluous blanks from each command line being added to the
# history list
setopt HIST_REDUCE_BLANKS

# Do not enter command lines into the history list if they are
# duplicates of the previous event.
setopt HIST_IGNORE_DUPS

#------------------------------------------------

#------------------------------------------------
# Command line editing --------------------------

# set emacs-style keymap (but notice that it is automatically set
# looking at the EDITOR environment variable)
bindkey -e

#better mimiking of emacs behaviour
bindkey "^ " set-mark-command 
bindkey "^w" kill-region      


#------------------------------------------------


#------------------------------------------------
# Misc ------------------------------------------

# process time reported if greater then...
REPORTTIME=2

# automatically remove duplicates from these arrays
typeset -U path cdpath fpath manpath

# produce the character used by screen program as escape char (to be
# used in console NOT in X, for X see .Xmodemap)
if [[ $TERM == linux ]]; then
    echo "keycode 125 = 0x1f" | loadkeys
fi

#remove stale screen sessions
if [ -e /usr/bin/screen ]; then
    screen -wipe > /dev/null
fi

#------------------------------------------------

#moving the output to the cut&paste stack of zsh from the command line
#---------------------------------------------------------------------

#define a simple copy function
gbstore() { 
    gb_store=`cat -`
}

#redefine the function which is automatically called when line editing
#begins (thank to Peter Stephenson)
zle-line-init () {
 if [[ -n $gb_store ]]
 then
    killring=("$CUTBUFFER" "${(@)killring[1,-2]}")
    CUTBUFFER=$gb_store
    gb_store=
 fi
}

#add this function to the list of widgets
zle -N zle-line-init
