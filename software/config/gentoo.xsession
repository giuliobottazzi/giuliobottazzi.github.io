#!/bin/bash

# Filename:     .xsession
# Author:       Giulio Bottazzi
# Lat modified: August 06 2009


# Start the SSH and GPG agent the keychain way
# ============================================

# It should use a graphical password asker (ssh-askpass).

# Expiration time of gpg private keys is set in the file
# '.gnupg/gpg-agent.conf' using options 'default-cache-ttl' and
# 'qmax-cache-ttl'. For instance to have private keys stored for 1
# year maximum and 1 month if never used add the following lines:
#
# default-cache-ttl 2592000
# qmax-cache-ttl 31536000


KEYCHAIN=`which keychain 2>/dev/null`
if [[ $KEYCHAIN != "" ]]; then
# To have all keys loaded at session start
# $KEYCHAIN id_rsa id_dsa BAB0A33F
# Just start keychain without loading keys
  $KEYCHAIN
  [[ -f $HOME/.keychain/$HOSTNAME-sh ]] && source $HOME/.keychain/$HOSTNAME-sh
  [[ -f $HOME/.keychain/$HOSTNAME-sh-gpg ]] && source  $HOME/.keychain/$HOSTNAME-sh-gpg
fi
# ====================================


# Define usefull variables
# ========================

export BROWSER=chromium
export TERMCMD=urxvt
export TERM=rxvt-unicode
export EDITOR=emacs
export INFOPATH=$INFOPATH:/usr/local/info
#US locale with unicode support
export LANG="en_US.utf8"
# ========================


# Set the background
# ==================
#xsetroot -solid black
# ==================


# Set the screen special character
# ================================

#xmodmap $HOME/.Xmodmap

xmodmap -e "keycode 133 = 0x1f"
# ================================


# Adjust synaptic touchpad parameters
# ===================================

#two fingers scrolling
xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Two-Finger Scrolling" 8 1
xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Two-Finger Scrolling" 8 1 1
xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Two-Finger Pressure" 32 10
xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Two-Finger Width" 32 8

#horizontal scrolling
xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Edge Scrolling" 8 1 1 0
xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Scrolling Distance" 32  73, 73
# ===================================


# Start the session
# =================

# Uncomment the desired entry:

# Fluxbox with consolekit, G.B. 12/2010
#if test -z "$DBUS_SESSION_BUS_ADDRESS" ; then
    ## if not found, launch a new one
#    eval 'dbus-launch --sh-syntax --exit-with-session'
#    echo "D-Bus per-session daemon address is: $DBUS_SESSION_BUS_ADDRESS"
#fi
#exec /usr/bin/ck-launch-session /usr/bin/startfluxbox
#/usr/bin/startfluxbox
exec ck-launch-session dbus-launch --sh-syntax --exit-with-session /usr/bin/startfluxbox

# Fluxbox
#/usr/bin/startfluxbox

# XFCE4
# startxfce4

# WindowMaker
#/usr/bin/wmaker

# Ratpoison
#/usr/bin/ratpoison 

# WindowMaker Improved II
#/usr/local/bin/wmii
# =================
