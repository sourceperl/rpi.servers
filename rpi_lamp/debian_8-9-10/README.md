# Server : basic LAMP server

## What this server do

- install a web server Apache2 with PHP (5 for jessie/7 for stretch)
- install a database (MySQL for jessie or MariaDB for stretch)
- also add phpmyadmin for manage the database

## Setup

    # define some const like hostname or mysql root password
    nano setup.sh
    # launch setup
    sudo setup.sh
