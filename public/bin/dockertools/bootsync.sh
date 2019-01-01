#!/bin/sh

# Disable DHCP and set the static IP address
pkill udhcpc
ifconfig eth1 192.168.99.23

