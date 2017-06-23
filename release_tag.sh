#!/usr/bin/env bash
set -e

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
