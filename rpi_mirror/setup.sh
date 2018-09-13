#!/bin/bash
# setup server script from a custom Raspbian image
#
# form source image: rpi_jessie_lite-xxxxxxxx-custom_fr.img

# !!! define this before launch !!! 
NEW_HOSTNAME="rpi_mirror"
UUID_HDD="5587bc99-083d-4c06-a8f2-07980538f418" # "3df31d1c-2caa-43b1-b33b-5d35a23f6c19"
UUID_KEY="F3B5-A552" #"3539-27EE"

# vars
NAME=$(basename $0)

# check root
[ $EUID -ne 0 ] && { printf "ERROR: $NAME needs to be run by root\n" 1>&2; exit 1; }

# current dir is script dir
cd "$(dirname "$0")"

# check UUIDs
[ ! -b /dev/disk/by-uuid/$UUID_HDD ] && { printf "ERROR: UUID_HDD not exist\n" 1>&2; exit 1; }
[ ! -b /dev/disk/by-uuid/$UUID_KEY ] && { printf "ERROR: UUID_KEY not exist\n" 1>&2; exit 1; }

# exit on error
set -e

# install packages
#apt-get update && apt-get -y upgrade
apt-get -y install apt-mirror apache2

# configure fstab (add mountpoints for USB HDD and USB KEY)
mkdir -p /mnt/USB_HDD
mkdir -p /mnt/USB_KEY

L1="# fix USB HDD/key mountpoints for mirror"
L2="UUID=$UUID_HDD  /mnt/USB_HDD  ext4  auto,exec,nofail  0  0"
L3="UUID=$UUID_KEY  /mnt/USB_KEY  vfat  auto,uid=pi,gid=pi,exec,nofail,noatime  0  0"
FILE=/etc/fstab
grep -q "$L1" "$FILE" || echo "$L1" >> "$FILE"
grep -q "$L2" "$FILE" || echo "$L2" >> "$FILE"
grep -q "$L3" "$FILE" || echo "$L3" >> "$FILE"

mount /mnt/USB_HDD
mount /mnt/USB_KEY

# configure apt-mirror (@www mirror -> HDD)
mkdir -p /mnt/USB_HDD/raspbian
chown -R apt-mirror:apt-mirror /mnt/USB_HDD/raspbian
cp etc/apt/mirror.list.raspbian /etc/apt/

# configure cron for apt-mirror
cp etc/cron.d/apt-mirror-raspbian /etc/cron.d/
service cron reload

# configure usb-mirror (HDD -> USB key)
mkdir -p /mnt/USB_KEY/raspbian
cp usr/local/bin/usb-mirror-raspbian /usr/local/bin/
chmod +x /usr/local/bin/usb-mirror-raspbian

# configure cron for usb-mirror
cp etc/cron.d/usb-mirror-raspbian /etc/cron.d/
service cron reload

# configure apache2
rm -f /var/www/html/index.html
ln -fs /mnt/USB_HDD/raspbian/mirror/archive.raspberrypi.org/ archive.raspberrypi.org
ln -fs /mnt/USB_HDD/raspbian/mirror/mirrordirector.raspbian.org/  mirrordirector.raspbian.org

# change the hostname
CURRENT_HOSTNAME=$(cat /proc/sys/kernel/hostname)
echo "$NEW_HOSTNAME" > /etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# end messages
echo "setup finish, take care to:"
echo "-> make a reboot to update hostname"
echo "-> add a network conf if don't use standard eth0 with DHCP"
echo "-> manual check of /etc/fstab:"
cat /etc/fstab
