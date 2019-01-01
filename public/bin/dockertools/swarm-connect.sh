#!/bin/bash

# Connect to the swarm instance

SWARM=mysql-shards
echo 'eval $(docker-machine env --swarm ${SWARM}-manager)'
