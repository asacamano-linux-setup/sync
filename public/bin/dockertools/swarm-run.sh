#!/bin/bash

# This script sets up a docker swarm with four small machines to run the four shards as replicas

# See https://docs.docker.com/swarm/install-w-machine/

SWARM=mysql-shards

eval $(docker-machine env ${SWARM}-manager)
export DOCKER_HOST=$(docker-machine ip ${SWARM}-manager):3376

# Now launch the processes scaled


set -xv
docker-compose scale mysql_0=2 mysql_1=2
set +xv
