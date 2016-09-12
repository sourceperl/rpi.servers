#!/bin/bash
# setup server: add custom dts_hotline to flyspray service

# vars
NAME=$(basename $0)

# check root
[ $EUID -ne 0 ] && { printf "ERROR: $NAME needs to be run by root\n" 1>&2; exit 1; }

# exit on error
set -e

# current dir is script dir
cd "$(dirname "$0")"

# update flyspray DB
echo "update DB"
zcat data/flyspray_hotline_dts_db.sql.gz | mysql --defaults-file=/etc/mysql/debian.cnf flyspray

# update web server files
echo "update web files"
sed -i "s/'Type de tâche'/'Equipe DTS'/g" /srv/flyspray/lang/fr.php
sed -i "s/'Catégorie'/'Exploitant'/g" /srv/flyspray/lang/fr.php
sed -i "s/'Etat'/'Etat ticket'/g" /srv/flyspray/lang/fr.php

# end messages
echo "finish: all done"
echo "-> flypray available at http://<SERVER_IP>/flyspray"
echo "-> log to flyspray with user/password: admin/12345678 and change this..."
