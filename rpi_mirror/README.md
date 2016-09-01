# Server : @www Raspbian local mirror

## Hardware

       Raspberry Pi -- USB port 1 -> HDD for mirror image (ext4 part)
                    |- USB port 2 -> USB key (fat32 part)

## What this server do

- a fixed HDD receive daily raspbian mirror
- an optional USB key mirror the HDD raspbian when connect to the Pi
- a web server provide http://RPI_IP/raspbian for apt update from other Pi

## Setup

    # !!! connect USB HDD and USB key before setup !!!
    # define some const like hostname or disk UUID in script header
    nano setup.sh
    # launch setup
    sudo setup.sh
