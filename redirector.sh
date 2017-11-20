#!/bin/bash
#============================================================================
# Filename   : redirector.sh
# Author     : Joel Kirch
# Date       : 17 November 2017
# Version    : 0.1
# Copyright  : Copyright © 2017 Joel Kirch
#              All rights reserved. See LICENSE file.
#              This project is licensed under the BSD 2-Clause license, it is
#              made possible by open source software.
#
# Description: Forwards ALL TCP/80 and TCP/443 traffic to the destination IP
#              address specified in the global variable DEST_IP. This script
#              also allows TCP/22 (SSH) traffic to connect.
#
# Usage:       After updating the values in the global variable section,
#              run this script as root (or with sudo).
#
# Credits:     The Bash Hackers Wiki - http://wiki.bash-hackers.org
#              /howto/getopts_tutorial
#              Mark Longair - https://stackoverflow.com/questions/
#              13015206/variables-validation-name-and-ip-address-in-bash#13015609
#              steeldriver - https://askubuntu.com/questions/396837
#              /detecting-the-name-of-a-network-device-in-bash#396909
#
# Warning    : This code does NO 'real' error checking, use at your own risk!
#============================================================================

# GLOBALS
DEST_IP='111.111.111.121'
INTERFACE='eth2'

display_usage() {
  cat <<EOF
  Usage: $0 [-h] [-d] <ip address> [-i] <interface>
  -h  display this help message
  -d  set destination IP address (overrides the global: $DEST_IP)
  -i  set network inferface (overrides the global: $INTERFACE)
EOF
  exit 0
}

validate_ip_format(){
IP_ADDRESS=$OPTARG
if echo "$IP_ADDRESS" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null
then
    # Then the format looks right - check that each octect is less than or equal to 255
    VALID_IP_ADDRESS="$(echo $IP_ADDRESS | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
    if [ -z "$VALID_IP_ADDRESS" ]
    then
        echo "The IP address wasn't valid; octets must be less than 256"
        exit 1
    else
        #echo "The IP address was valid"
        DEST_IP=$VALID_IP_ADDRESS
    fi
else
    echo "The IP address was malformed"
    display_usage
    exit 1
fi
}

validate_nic(){
NIC=$OPTARG
#echo $NIC
avail_nics=$(ls /sys/class/net)
#echo $avail_nics
if echo "$NIC" | grep -x "$avail_nics" > /dev/null
  then
  #echo "The NIC was valid"
  INTERFACE=$NIC
else
  echo "The NIC was not valid"
  display_usage
  exit 1
fi
}

while getopts ":hd:i:" opt; do
  case $opt in
    h)
      #echo "-h was triggered" >&2
      display_usage
      ;;
    d)
      #echo "-d was triggered, Parameter: $OPTARG" >&2
      validate_ip_format
      ;;
    i)
      #echo "-i was triggered, Parameter: $OPTARG" >&2
      validate_nic
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

echo "Using $DEST_IP and $INTERFACE"

# Check to see if the script is being executed with correct privs
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or with sudo."
  exit
fi

# Check to see if firewalld is installed and install it when needed
yum -q list installed firewalld.noarch &> /dev/null && \
echo "firewalld is installed." || \
echo "firewalld is not installed. Installing now."; yum install -y firewalld.noarch

# enable firewalld service at boot time
systemctl enable firewalld

# start firewalld service
systemctl restart firewalld.service

# setup rule for ssh & interface to use
firewall-cmd --permanent --zone=external --add-service=ssh
firewall-cmd --permanent --zone=external --change-interface=$INTERFACE

# setup forwarding
firewall-cmd --permanent --zone=external --add-masquerade
firewall-cmd --permanent --zone=external --add-forward-port=port=80:proto=tcp:toport=80:toaddr=$DEST_IP
firewall-cmd --permanent --zone=external --add-forward-port=port=443:proto=tcp:toport=443:toaddr=$DEST_IP
firewall-cmd --reload

# display the rules
firewall-cmd --list-all --zone=external
