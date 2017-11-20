Collection of utilities for ITN263

## redirector.sh

This script will setup firewalld to forward all TCP/80 and TCP 443 traffic to the destination IP address specified in the global variable DEST_IP using the global variable INTERFACE. These can be overridden on the command line with the -d and -i flags. This script also allows TCP/22 (SSH) traffic to connect. All rules are using the EXTERNAL zone, and you can view / edit all permanant rules in the /etc/firewalld/zones/extneral.xml file. To use the script, (optionally) update the values in the global variable section, run this script as root (or with sudo).
