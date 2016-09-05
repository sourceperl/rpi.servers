# Server : basic DHCP server

## What this server do

- provide a DHCP server for LAN on eth0
- default is : 
  * DHCP on eth0 only, server at static IP 192.168.50.1
  * address from 192.168.50.10 to .100
  * no gateway

## Setup

    # define some const like hostname or static IP
    nano setup.sh
    # launch setup
    sudo setup.sh
