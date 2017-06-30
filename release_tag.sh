#!/usr/bin/env bash
set -e

# FIXME: Update this script to do something like this, especially the ROOT var
# 6/24/2017
# readonly ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
# docker build -f $ROOT/Dockerfile.oracle-jdk -t islandora/claw-karaf:oracle-jdk $ROOT
# docker build -f $ROOT/Dockerfile.open-jdk -t islandora/claw-karaf:open-jdk $ROOT
# # Open JDK is the default implementation.
# docker tag islandora/claw-karaf:open-jdk islandora/claw-karaf:latest


if [[ "$1" == "" ]] ; then
    echo "You did not specify a new tag for the container you're build."
    echo "Please try again with something like v1.1.0"
    return 3
else
    TAG_VERSION="$1"
fi

ID=$(docker build -q -t bossjones/boss-docker-jhbuild-pygobject3:$TAG_VERSION .)
SHA=$(echo $ID | cut -d\: -f2)
echo $ID
echo $SHA
docker tag $ID bossjones/boss-docker-jhbuild-pygobject3:$TAG_VERSION
docker push bossjones/boss-docker-jhbuild-pygobject3:$TAG_VERSION
