#!/usr/bin/env bash

mkdir -p /home/pi/gnome

# Install jhbuild if not done
if [[ ! -f "/usr/local/bin/jhbuild" ]] && [[ -f "/home/pi/jhbuild/autogen.sh" ]] || [[ "${FORCE_BUILD_JHBUILD}" = "" ]]; then
    echo "****************[JHBUILD]****************" && \
    cd /home/pi && \
    if test ! -d /home/pi/jhbuild; then git clone https://github.com/GNOME/jhbuild.git && \
    cd jhbuild; else echo "exists" && cd jhbuild; fi && \
    git checkout 86d958b6778da649b559815c0a0dbe6a5d1a8cd4 && \
    ./autogen.sh --prefix=/usr/local > /dev/null && \
    make > /dev/null && \
    sudo make install > /dev/null && \
    sudo chown pi:pi -R /usr/local/ && \
    chown pi:pi -R /home/pi/jhbuild
else
    # if we don't need to re-build
    echo "****************[HEY GUESS WHAT]****************"
    echo "****************[JHBUILD IS RDY]****************"
    [[ ! -f "/usr/local/bin/jhbuild" ]] && echo 'TRUE: ! -f "/usr/local/bin/jhbuild"' || echo 'FALSE: ! -f "/usr/local/bin/jhbuild"'
    [[ -f "/home/pi/jhbuild/autogen.sh" ]] && echo 'TRUE: -f "/home/pi/jhbuild/autogen.sh"' || echo 'FALSE: -f "/home/pi/jhbuild/autogen.sh"'
    [[ $FORCE_BUILD_JHBUILD = 1 ]] && echo 'TRUE: $FORCE_BUILD_JHBUILD = 1' || echo 'FALSE: $FORCE_BUILD_JHBUILD = 1'
fi
