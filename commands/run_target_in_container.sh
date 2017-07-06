#   either ssh key or agent is needed to pull adobe-platform sources from git
#   this supplies to methods

set -o errexit
set -o pipefail

TARGET="$1"
SSH1=""
SSH2=""
SHA=${SHA:-"$(git rev-parse HEAD)"}

if [ ! -e /.dockerenv -o ! -z "$JENKINS_URL" ]; then
    # AWS environment variables to pass through to the container
    echo
    echo
    echo "-----------------------------------------------------"
    echo "Running target \"$TARGET\" inside Docker container..."
    echo "-----------------------------------------------------"
    echo
    set -x
    docker run -i --rm $SSH1 $SSH2 \
        --name=flightdirector_make_docker_$TARGET \
        -e sha=$SHA \
        -v $PWD:/go/src/git.corp.adobe.com/adobe-platform/flight-director \
        -w /go/src/git.corp.adobe.com/adobe-platform/flight-director \
        adobe-platform/flight-director:dev \
        make $TARGET
else
    make $TARGET
fi

