#Author: Giulio Bottazzi
#Last Modified:  Time-stamp: <2011-06-18 23:54:47 Giulio Bottazzi>

#set the name of the user
export NAME="Giulio Bottazzi"

#set some default variables
export BROWSER=chromium
export TERMCMD=urxvt
export EDITOR=emacs
if which ssh-askpass-fullscreen > /dev/null; then
    export SUDO_ASKPASS=`which ssh-askpass-fullscreen`
fi

#fix PATH
if [[ ! $PATH == */usr/local/bin* ]]; then export PATH=$PATH:/usr/local/bin ; fi
if [[ ! $PATH == *"$HOME"/bin* ]]; then export PATH=$PATH:"$HOME"/bin ; fi

#fix INFOPATH
if [[ ! $INFOPATH == */usr/local/info* ]]; then export INFOPATH=$INFOPATH:/usr/local/info ; fi

#if [[ ! $PATH == */usr/bin/wrappers* ]];
#then export PATH=/usr/bin/wrappers:${PATH};
#fi

#------------------------------------------------
# Localization ----------------------------------

#Italian, no unicode
#export LC_ALL="it_IT@euro"
#export LANG="it_IT@euro"
#export LC_CTYPE="it_IT@euro"

#English + euro, unicode
#generate errors in Xlib
#export LC_CTYPE="en_IE.utf8@euro"
#export LANG="en_IE.utf8@euro"

#English, unicode
export LANG="en_US.utf8"
export LC_CTYPE="en_US.utf8"

#Italian + euro, unicode
#export LC_CTYPE="it_IT.utf8@euro"
#export LANG="it_IT.utf8@euro"

#------------------------------------------------

#Visualization command used by scipy
export SCIPY_PIL_IMAGE_VIEWER=display

#needed by gpg-agent
GPG_TTY=`tty`
export GPG_TTY
