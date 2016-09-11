#!/bin/bash
# setup server: add custom flyspray service to rpi_lamp based

# generate random 16 chars password
FLY_PWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)

# vars
NAME=$(basename $0)

# check root
[ $EUID -ne 0 ] && { printf "ERROR: $NAME needs to be run by root\n" 1>&2; exit 1; }

# exit on error
set -e

# current dir is script dir
cd "$(dirname "$0")"

# configure DB
echo "configure DB"
SQL="CREATE DATABASE IF NOT EXISTS flyspray DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
echo $SQL | mysql --defaults-file=/etc/mysql/debian.cnf
SQL="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES ON flyspray.*
     TO flysprayuser@localhost IDENTIFIED BY '$FLY_PWD';"
echo $SQL | mysql --defaults-file=/etc/mysql/debian.cnf

# init flyspray DB
echo "init DB"
zcat data/flyspray_db.sql.gz | mysql --defaults-file=/etc/mysql/debian.cnf flyspray

# extract web server files
echo "extract web files"
tar -xzf data/flyspray_www.tar.gz -C /srv/.
# set root .htacess file
mv /srv/flyspray/htaccess.dist /srv/flyspray/.htaccess
sed -i "s/#\s*RewriteBase/RewriteBase/g" /srv/flyspray/.htaccess
# www-data own all files
chown -R www-data:www-data /srv/flyspray

# add password to flyspray web app
sed -i "s/<FLY_PWD>/$FLY_PWD/g" /srv/flyspray/flyspray.conf.php

# configure web server (apache2)
cp etc/apache2/conf-available/flyspray.conf /etc/apache2/conf-available/
ln -sf ../conf-available/flyspray.conf /etc/apache2/conf-enabled/flyspray.conf
# set mod_rewrite on
a2enmod rewrite
service apache2 restart

# end messages
echo "finish: all done"
echo "-> flypray available at http://<SERVER_IP>/flyspray"
echo "-> log to flyspray with user/password: admin/12345678 and change this..."
