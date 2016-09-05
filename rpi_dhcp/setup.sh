#!/bin/bash
# setup server script from a custom Raspbian image
#
# form source image: rpi_jessie_lite-xxxxxxxx-custom_fr.img

# !!! define this before launch !!! 
NEW_HOSTNAME="rpi_dhcp"
IP_SUBNET="192.168.50.1/24"
#GATEWAY="192.168.50.1"
INTERFACES="eth0"

# vars
NAME=$(basename $0)

# check root
[ $EUID -ne 0 ] && { printf "ERROR: $NAME needs to be run by root\n" 1>&2; exit 1; }

# current dir is script dir
cd "$(dirname "$0")"

# generate file(s) not readable only by root.
umask 022

# install packages
apt-get update && apt-get -y upgrade
apt-get install -y isc-dhcp-server

# set static IP address
L1="interface eth0"
L2="static ip_address=$IP_SUBNET"
[[ $IP_GATEWAY ]] && L3="static routers=$IP_GATEWAY"
FILE=/etc/dhcpcd.conf
if grep -q "$L1" "$FILE"
then
    printf "static config already exist, skip config\n" 1>&2
else
    echo "" >> "$FILE"
    echo "# static configuration" >> "$FILE"
    echo "$L1" >> "$FILE"
    echo "$L2" >> "$FILE"
    [[ $L3 ]] && echo "$L3" >> "$FILE"
fi

# update isc-dhcp-server conf
cp etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf

INITCONFFILE="/etc/default/isc-dhcp-server"
if [ -n "$INTERFACES" ]; then
    TMPFILE="$(mktemp -q ${INITCONFFILE}.new.XXXXXX)"
    sed -e "s,^[[:space:]]*INTERFACES[[:space:]]*=.*,INTERFACES=\"${INTERFACES}\"," <${INITCONFFILE} >${TMPFILE}
    cp ${TMPFILE} ${INITCONFFILE}
    rm ${TMPFILE}
fi

# change the hostname
CURRENT_HOSTNAME=$(cat /proc/sys/kernel/hostname)
echo "$NEW_HOSTNAME" > /etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# end messages
echo "setup finish, take care to:"
echo "-> make a reboot to update hostname, restart network and DHCP server"
echo "-> check network conf"

