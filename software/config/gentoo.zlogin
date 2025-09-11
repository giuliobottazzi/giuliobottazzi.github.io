# Filename:     .zlogin
# Author:       Giulio Bottazzi
# Lat modified: Mon Dec 31 2007

#start keychain in console. See the file
# '.gnupg/gpg-agent.conf' for time to expiry
if [[ $DISPLAY == "" ]] {
	KEYCHAIN=`whence keychain`
	if [[ $KEYCHAIN != "" ]] {
#               if all key are loaded at session start
#		$KEYCHAIN id_rsa id_dsa BAB0A33F
		$KEYCHAIN
		[[ -f $HOME/.keychain/$HOST-sh ]] && \
		    source $HOME/.keychain/$HOST-sh
		[[ -f $HOME/.keychain/$HOST-sh-gpg ]] && \
		    source  $HOME/.keychain/$HOST-sh-gpg
	    }
    }
