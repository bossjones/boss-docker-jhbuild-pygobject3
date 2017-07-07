#!/usr/bin/env bash

touch /home/pi/.execline-shell
cat <<EOF > /home/pi/.execline-shell
#!/usr/bin/execlineb -S0

# Eg. /home/pi
importas HOME HOME

# $ENV is $HOME/.shrc in newer versions of the Bourne Shell
# source: https://en.wikipedia.org/wiki/Unix_shell
export ENV ${HOME}/.shrc

# source: https://github.com/dragonmaus/home-old/tree/master/.sh
# export ENVD ${HOME}/.sh

ssh-agent
# NOTE: tryexec program
# tryexec executes into a command line, with a fallback.
# tryexec [ -n ] [ -c ] [ -l ] [ -a argv0 ] { prog1... } prog2...
# -a argv0 : argv0. Replace prog's argv[0] with argv0. This is done before adding a dash, if the -l option is also present.
# https://skarnet.org/software/execline/tryexec.html
tryexec -a sh
{
  bash $@
}
sh $@
EOF

sudo chown pi:pi -R /home/pi/
