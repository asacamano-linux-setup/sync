#!/bin/bash

# This script sets up a docker swarm with four small machines to run the four shards as replicas

# See also:
# https://docs.docker.com/engine/userguide/networking/get-started-overlay/
#
# and
#
# https://docs.docker.com/swarm/install-w-machine/

SWARM=mysql-shards
SWARM_MEMORY_PER_BOX=768
SWARM_CPU_PER_BOX=1

function build_or_start() {
  machine_name=${SWARM}-${1}
  shift
  # Docker machine output
  # NAME       ACTIVE   DRIVER       STATE
  state=$( docker-machine ls | grep '^'$machine_name | awk '{print $4}' )
  if [[ $state == "" ]]; then
    set -xv
    docker-machine create --driver virtualbox \
      --virtualbox-memory=${SWARM_MEMORY_PER_BOX} --virtualbox-cpu-count=${SWARM_CPU_PER_BOX} \
      $* \
      ${machine_name}
    set +xv
  elif [[ $state == "Stopped" ]]; then
    set -xv
    docker-machine start ${machine_name}
    set +xv
  elif [[ $state != "Running" ]]; then
    echo "Unknown state $state for $machine_name : exiting"
    exit 1
  fi
}

function run_or_start() {
  container_name=$1
  shift
  state=$( docker ps -a -f name=${container_name} | tail -n +2 )
  if [[ $state == "" ]]; then
    set -xv
    docker run --name $container_name $*
    set +xv
  else
    state=$( docker ps -f name=${container_name} | tail -n +2 )
    if [[ $state == "" ]]; then
      set -xv
      docker start $container_name
      set +xv
    else
      echo Container $container_name already running
    fi
  fi
}


# First, build or start the discovery machine
build_or_start consul
eval $( docker-machine env ${SWARM}-consul )
run_or_start consul -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap
consul_ip=$( docker-machine ip ${SWARM}-consul )
if [[ $consul_ip == "" ]]; then
  echo "Couldn't get consul IP through docker-machine ip ${SWARM}-consul"
  exit 1
fi



# Next, build or start the manager machine
build_or_start manager --swarm --swarm-master \
  --swarm-discovery="consul://${consul_ip}:8500" \
  --engine-opt="cluster-store=consul://${consul_ip}:8500" \
  --engine-opt="cluster-advertise=eth1:2376"

# Next, build or start the nodes
for node in 0 1 2 3; do
  build_or_start node-${node} --swarm \
  --swarm-discovery="consul://${consul_ip}:8500" \
  --engine-opt="cluster-store=consul://${consul_ip}:8500" \
  --engine-opt="cluster-advertise=eth1:2376"
done

echo "Don't forget:"
echo "eval $(docker-machine env --swarm ${SWARM}-manager)"
