#!/bin/bash

# This script sets up a docker swarm with overlay networking.

# See also:
#
# https://docs.docker.com/engine/userguide/networking/get-started-overlay/
#
SWARM=mysql-shards

function make_network() {
  network_name=${1}
  shift
  # Docker network ls output
  # NETWORK ID          NAME                          DRIVER
  network=$( docker network ls -f name=${network_name} | tail -n +2 )
  if [[ $network == "" ]]; then
    set -xv
    docker network create --driver overlay --subnet=10.255.250.0/24 $network_name
    set +xv
  else
    echo "Network $network_name exists already."
  fi
}

# Connect to the the manager
echo 'eval $(docker-machine env --swarm ${SWARM}-manager)'

make_network mysql_default
