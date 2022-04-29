#!/bin/bash
# setup server script from a custom Raspbian image (for debian 8,9 and 10)
#
# form source image: rpi_jessie_lite-xxxxxxxx-custom_fr.img
#                or: rpi_stretch_lite-xxxxxxxx-custom_fr.img

# !!! define this before launch !!! 
NEW_HOSTNAME="rpi_lamp"
MYSQL_PWD="admin"

# vars
NAME=$(basename $0)
DEBIAN=$(sed 's/\..*//' /etc/debian_version)

# check root
[ $EUID -ne 0 ] && { printf "ERROR: $NAME needs to be run by root\n" 1>&2; exit 1; }

# exit on error
set -e

# current dir is script dir
cd "$(dirname "$0")"

# global env
export DEBIAN_FRONTEND=noninteractive

# define mysql params
#debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PWD"
#debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PWD"

# define phpmyadmin params
debconf-set-selections <<<  "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
debconf-set-selections <<<  "phpmyadmin phpmyadmin/dbconfig-install boolean true"
#debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/admin-user string root"
#debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PWD"
#debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PWD"
#debconf-set-selections <<<  "phpmyadmin phpmyadmin/mysql/app-pass password your-app-db-pwd"
#debconf-set-selections <<<  "phpmyadmin phpmyadmin/app-password-confirm password your-app-pwd"

# install packages (for debian jessie or stretch)
#apt-get update && apt-get -y upgrade
[ $DEBIAN -eq 8 ] && { apt-get install -y apache2 php5 mysql-server php5-mysql phpmyadmin; }
[ $DEBIAN -eq 9 ] && { apt-get install -y apache2 php7.0 mysql-server php7.0-mysql phpmyadmin; }
[ $DEBIAN -eq 10 ] && { apt-get install -y apache2 php7.3 mariadb-server php7.3-mysql phpmyadmin; }

# secure mysql
mysql --defaults-file=/etc/mysql/debian.cnf <<< "DELETE FROM mysql.user WHERE User='';"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "DROP DATABASE IF EXISTS test;"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
# create admin user for phpmyadmin
mysql --defaults-file=/etc/mysql/debian.cnf <<< "CREATE USER 'admin'@'localhost' IDENTIFIED BY '$MYSQL_PWD';"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;"
mysql --defaults-file=/etc/mysql/debian.cnf <<< "FLUSH PRIVILEGES;"

# change the hostname
CURRENT_HOSTNAME=$(cat /proc/sys/kernel/hostname)
echo "$NEW_HOSTNAME" > /etc/hostname
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# end messages
echo "setup finish, take care to:"
echo "-> make a reboot to update hostname"
echo "-> ensure default admin password used for phpmyadmin is changed"
echo "-> add a network conf if don't use standard eth0 with DHCP"
