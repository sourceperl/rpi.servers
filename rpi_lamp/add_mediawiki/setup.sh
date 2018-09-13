#!/bin/bash
# setup server: add mediawiki service to rpi_lamp based

# vars
NAME=$(basename $0)

# check root
[ $EUID -ne 0 ] && { printf "ERROR: $NAME needs to be run by root\n" 1>&2; exit 1; }

# exit on error
set -e

# current dir is script dir
cd "$(dirname "$0")"

# install mediawiki
sudo apt-get install mediawiki

# html redirect for root path
cat <<EOF | sudo tee /var/www/html/index.html 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="refresh" content="0; URL=/mediawiki" />
  </head>
  <body>
  </body>
</html>
EOF

# end messages
echo "finish: all done"
echo "-> connect to http://<SERVER_IP>/mediawiki to complete setup"
