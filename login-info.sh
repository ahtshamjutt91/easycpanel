#!/bin/bash

echo "######################################################################"
echo "#                          Welcome Back                              #"
echo "#                                                                    #"
echo "#        (Server is setup, optimized & secured by ahtshamjutt.com)   #"
echo "######################################################################"


# Basic info
HOSTNAME=`uname -n`
ROOT=`df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }'`

# System load
MEMORY1=`free -t -m | grep Total | awk '{print $3" MB";}'`
MEMORY2=`free -t -m | grep "Mem" | awk '{print $2" MB";}'`
LOAD1=`cat /proc/loadavg | awk {'print $1'}`
LOAD5=`cat /proc/loadavg | awk {'print $2'}`
LOAD15=`cat /proc/loadavg | awk {'print $3'}`

#Login Information
Failed=$((`lastb | wc -l` - 2)) ; > /var/log/btmp
Last5=$(last -5 root)

echo "
===============================================
 - Hostname....................: $HOSTNAME
 - Disk Space..................: $ROOT currently used
 - CPU usage...................: $LOAD1, $LOAD5, $LOAD15 (1, 5, 15 min)
 - Memory used.................: $MEMORY1 / $MEMORY2
 - Failed logins ..............: $Failed ( since last successful login)
 - Last 5 successful Logins ...:
$Last5
===============================================
"