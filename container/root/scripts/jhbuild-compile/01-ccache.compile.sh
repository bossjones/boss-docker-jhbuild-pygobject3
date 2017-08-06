#!/usr/bin/env bash
# Configure ccache compiler cache. This shall help speeding up compilation
echo "****************[ccache]****************" && \
CCACHE=$(which ccache)
sudo -u "pi" mkdir -p "/home/pi/jhbuild/bin"
if [ "$CCACHE" ]; then
  for compiler in cc gcc c++ g++; do
    if [ ! -e "/home/pi/jhbuild/bin/$compiler" ]; then
      sudo -u "pi" ln -s "$CCACHE" "/home/pi/jhbuild/bin/$compiler"
    fi
  done
fi



# enable ccache
export CCACHE_DIR=/ccache
# export PATH=/usr/lib/ccache:$PATH

# TODO: Implent this guy here
# CCACHE=$(which ccache)
# if [ "$CCACHE" ]; then
#   for compiler in cc gcc c++ g++; do
#     if [ ! -e "$USER_HOME/jhbuild/install/bin/$compiler" ]; then
#       sudo -u "pi" ln -s "$CCACHE" "$USER_HOME/jhbuild/install/bin/$compiler"
#     fi
#   done
# fi


# ##########

# ccache -M 2G
# (where 2G is the size the cache). Create symlinks to CCache for the compiler in ~/bin:

mkdir -p /home/pi/bin
cd /home/pi/bin
for cmd in cc gcc c++ g++; do
  ln -s /usr/bin/ccache $cmd
done
# It is possible to check the status of the cache including cache hit rates with the following command:

# ccache -s

export PATH=/home/pi/bin:$PATH
export PATH=/usr/lib/ccache:${PATH}

#  pi  ⎇  master  ~/gnome/gtk-doc   echo $PATH
# /usr/lib/ccache:/home/pi/bin:/home/pi/jhbuild/bin:/home/pi/jhbuild/sbin:/home/pi/.local/bin:/home/pi/jhbuild/bin:/home/pi/jhbuild/sbin:/usr/local/bin:/usr/local/sbin:/home/pi/jhbuild/bin:/home/pi/jhbuild/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#  pi  ⎇  master  ~/gnome/gtk-doc
