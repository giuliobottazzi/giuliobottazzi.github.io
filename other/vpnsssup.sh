#!/bin/sh

# VPC at SSSUP, start and shutdown script
# Copyright (C) 2008-2009 Giulio Bottazzi
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See <http://www.fsf.org/copyleft/gpl.txt>.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.

# Modified
#
# G.B. Mon Mar  February 2009
# corrected typo.
#
# G.B. Thu Oct 29 2009
# now connection name should be provided on the command line
#

#--------- modify the following parameters


#the script that turns ipsed on and off
DAEMON="/etc/init.d/ipsec"

#the ipsec executable; find it using `which ipsec`
IPSEC="/usr/sbin/ipsec"

#the name of the local DNS server
DNSSRV="/etc/init.d/dnsmasq"

#--------- don't modify after this line


USAGE="\n

Simple script to turn on and off the VPN connection to Scuola\n
Superiore Sant'Anna through SonicWall appliance. The script starts\n
both the daemon and the connection and takes care of setting up\n
hourly reestablishment of the connection.\n

\n
argument \t description\n
\n
start\t\t start VPN connection; require connection name, username and passwd\n
stop\t\t stop VPN connection; require connection name\n
status\t\t report status information; require connection name\n
help\t\t this help\n
"

if [[ $# -lt 1 ]] ; then
        echo "ERROR: provide at least one argument"
        echo -e ${USAGE}
        exit 1
fi

RETVAL=0
case "$1" in
    start)
	if [[ $# -lt 4 ]] ; then
	    echo "ERROR: provide connection, username and password"
	    echo -e ${USAGE}
	    exit 1
	fi
	CONN=${2}
	USERNAME=${3}
	PASSWD=${4}
	#check connection is not up already
	if ${IPSEC} whack --status 2>/dev/null | grep "${CONN}" | grep -q 'STATE_XAUTH_I1' ; then
	    echo "connection \"${CONN}\" is already up"
	    exit 1
	fi
	echo "starting connection \"${CONN}\" ..."
        #switch off ICMP packets redirection
	[[ -e /proc/sys/net/ipv4/conf/default/send_redirects ]] && echo 0 > /proc/sys/net/ipv4/conf/default/send_redirects
	[[ -e /proc/sys/net/ipv4/conf/default/accept_redirects ]] && echo 0 > /proc/sys/net/ipv4/conf/default/accept_redirects
	#activate ip forward
	echo 1 > /proc/sys/net/ipv4/ip_forward
	#start the daemon if not already up
	if [[ -e ${DAEMON} ]]; then
	    ${DAEMON} status > /dev/null || ${DAEMON} start
	else
	    echo "ipsec daemon not found"
	    exit -1
	fi
	#start the connection
	sleep 2
	${IPSEC} whack --status | grep -q 'STATE_XAUTH_I1' || ${IPSEC} whack --name ${CONN} --xauthname ${USERNAME} --xauthpass ${PASSWD} --initiate > /dev/null
	#add hourly connection restart
	echo "#! /bin/sh 
${IPSEC} whack --status && ${IPSEC} whack --name sonicwall --terminate ; ${IPSEC} whack  --name ${CONN} --xauthname $USERNAME --xauthpass $PASSWD --initiate
" >> /etc/cron.hourly/ipsec
	chmod +x /etc/cron.hourly/ipsec
	#start DNS server (if present)
	if [[ -e ${DNSSRV} ]]; then
	    ${DNSSRV} status > /dev/null || ${DNSSRV} start
	fi
	;;

    stop)
	if [[ $# -lt 2 ]] ; then
	    echo "ERROR: provide connection name"
	    echo -e ${USAGE}
	    exit 1
	fi
	CONN=${2}
	echo "stopping connection \"${CONN}\" ..."
	#stop the connection
	${IPSEC} whack --name ${CONN} --terminate
	#remove hourly connection restart
	if [[ -e /etc/cron.hourly/ipsec ]]; then
	    grep -v \"${CONN}\" /etc/cron.hourly/ipsec > /etc/cron.hourly/ipsec
	fi
	#stop the daemon
	#${DAEMON} stop
	#remove hourly connection restart
	#[[ -e /etc/cron.hourly/ipsec ]] && rm /etc/cron.hourly/ipsec
	;;
    
    status)
	if [[ $# -lt 2 ]] ; then
	    echo "ERROR: provide connection name"
	    echo -e ${USAGE}
	    exit 1
	fi
	CONN=${2}
	#check daemon
	echo -n "Openswan daemon is "
	if ${DAEMON} status > /dev/null ; then
	    echo "up"
	else
	    echo "down"
	fi
	#check connection
	echo -n "VPN connection \"${CONN}\" is "
	if ${IPSEC} whack --status 2>/dev/null | grep "${CONN}" | grep -q 'STATE_XAUTH_I1' ; then
	    echo "up"
	else
	    echo "down"
	fi
	
	RETVAL=1
	if ${DAEMON} status > /dev/null && ${IPSEC} whack --status | grep -q 'STATE_XAUTH_I1' ; then
	    RETVAL=0
	fi
	;;
    
    help|-h|--help)
	echo -e ${USAGE}
	;;
esac

exit "${RETVAL}"
