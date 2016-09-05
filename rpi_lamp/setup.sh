#!/bin/bash
# setup server script from a custom Raspbian image
#
# form source image: rpi_jessie_lite-xxxxxxxx-custom_fr.img

# !!! define this before launch !!! 
NEW_HOSTNAME="rpi_lamp"
MYSQL_PWD="mysql"

# vars
NAME=$(basename $0)

# check root
[ $EUID -ne 0 ] && { printf "ERROR: $NAME needs to be run by root\n" 1>&2; exit 1; }

# exit on error
set -e

# current dir is script dir
cd "$(dirname "$0")"

# global env
export DEBIAN_FRONTEND=noninteractive

# define mysql params
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PWD"

# define phpmyadmin params
debconf-set-selections <<<  "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
debconf-set-selections <<<  "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/admin-user string root"
debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PWD"
debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PWD"
#debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/app-pass password your-app-db-pwd"
#debconf-set-selections <<<  "phpmyadmin phpmyadmin/app-password-confirm password your-app-pwd"

# install packages
apt-get update && apt-get -y upgrade
apt-get install -y apache2 php5 mysql-server php5-mysql phpmyadmin

# secure mysql
mysql --defaults-file=/etc/mysql/debian.cnf <<< "DELETE FROM mysql.user WHERE User='';"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "DROP DATABASE IF EXISTS test;"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "FLUSH PRIVILEGES;"

# change the hostname
CURRENT_HOSTNAME=$(cat /proc/sys/kernel/hostname)
echo "$NEW_HOSTNAME" > /etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# end messages
echo "setup finish, take care to:"
echo "-> make a reboot to update hostname"
echo "-> add a network conf if don't use standard eth0 with DHCP"

