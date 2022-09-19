#!/bin/bash

# Main script to build the docker image
# Docker tags need to be manually updated in this file and in docker-build.sh

docker build -t 'rsubr/postgres-babelfish:2.1.1-pg14.3' .
