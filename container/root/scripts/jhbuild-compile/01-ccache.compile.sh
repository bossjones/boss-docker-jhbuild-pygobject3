#!/usr/bin/env bash
# Configure ccache compiler cache. This shall help speeding up compilation
echo "****************[ccache]****************" && \
CCACHE=$(which ccache)
sudo -u "pi" mkdir -p "/home/pi/jhbuild/install/bin"
if [ "$CCACHE" ]; then
  for compiler in cc gcc c++ g++; do
    if [ ! -e "/home/pi/jhbuild/install/bin/$compiler" ]; then
      sudo -u "pi" ln -s "$CCACHE" "/home/pi/jhbuild/install/bin/$compiler"
    fi
  done
fi



# enable ccache
export CCACHE_DIR=/ccache
export PATH=/usr/lib/ccache:$PATH
