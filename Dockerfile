FROM bossjones/boss-docker-python3:latest
MAINTAINER Malcolm Jones <bossjones@theblacktonystark.com>

# Prepare packaging environment
ENV DEBIAN_FRONTEND noninteractive

# # Ensure UTF-8 lang and locale
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:/usr/local/sbin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.

# FIXME: DO NOT SET env var USER
ENV UNAME "pi"

# /home/pi
ENV USER_HOME "/home/${UNAME}"

# /home/pi/dev
ENV PROJECT_HOME "/home/${UNAME}/dev"

ENV LANG C.UTF-8
ENV SKIP_ON_TRAVIS yes
ENV CURRENT_DIR $(pwd)
ENV GSTREAMER 1.0
ENV ENABLE_PYTHON3 yes
ENV ENABLE_GTK yes
ENV PYTHON_VERSION_MAJOR 3
ENV PYTHON_VERSION 3.5
ENV CFLAGS "-fPIC -O0 -ggdb -fno-inline -fno-omit-frame-pointer"
ENV MAKEFLAGS "-j4"

# /home/pi/jhbuild
ENV PREFIX "${USER_HOME}/jhbuild"

# /home/pi/gnome
ENV JHBUILD "${USER_HOME}/gnome"

# /home/pi/.virtualenvs
ENV PATH_TO_DOT_VIRTUALENV "${USER_HOME}/.virtualenvs"

# /home/pi/jhbuild/bin:/home/pi/jhbuild/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH ${PREFIX}/bin:${PREFIX}/sbin:${PATH}

# /home/pi/.virtualenvs/scarlett_os/lib
ENV LD_LIBRARY_PATH ${PREFIX}/lib:${LD_LIBRARY_PATH}

# /home/pi/jhbuild/lib/python3.5/site-packages:/usr/lib/python3.5/site-packages
ENV PYTHONPATH ${PREFIX}/lib/python${PYTHON_VERSION}/site-packages:/usr/lib/python${PYTHON_VERSION}/site-packages

# /home/pi/.virtualenvs/scarlett_os/lib/pkgconfig
ENV PKG_CONFIG_PATH ${PREFIX}/lib/pkgconfig:${PREFIX}/share/pkgconfig:/usr/lib/pkgconfig

# /home/pi/jhbuild/share:/usr/share
ENV XDG_DATA_DIRS ${PREFIX}/share:/usr/share

# /home/pi/jhbuild/etc/xdg
ENV XDG_CONFIG_DIRS ${PREFIX}/etc/xdg

ENV PYTHON /usr/bin/python3
ENV TERM xterm
ENV PACKAGES "python3-gi python3-gi-cairo"
ENV CC gcc

RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    dpkg-reconfigure -f noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial main restricted' | tee /etc/apt/sources.list && \
    echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ xenial main restricted' | tee -a /etc/apt/sources.list && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates main restricted' | tee -a /etc/apt/sources.list && \
    echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-updates main restricted' | tee -a /etc/apt/sources.list && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial universe' | tee -a /etc/apt/sources.list && \
    echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ xenial universe' | tee -a /etc/apt/sources.list && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates universe' | tee -a /etc/apt/sources.list && \
    echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-updates universe' | tee -a /etc/apt/sources.list && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial-security main restricted' | tee -a /etc/apt/sources.list && \
    echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-security main restricted' | tee -a /etc/apt/sources.list && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial-security universe' | tee -a /etc/apt/sources.list && \
    echo 'deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-security universe' | tee -a /etc/apt/sources.list && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial multiverse' | tee -a /etc/apt/sources.list && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates multiverse' | tee -a /etc/apt/sources.list && \
    echo 'deb http://security.ubuntu.com/ubuntu xenial-security main restricted' | tee -a /etc/apt/sources.list && \
    echo 'deb http://security.ubuntu.com/ubuntu xenial-security main restricted' | tee -a /etc/apt/sources.list && \
    echo 'deb http://security.ubuntu.com/ubuntu xenial-security universe' | tee -a /etc/apt/sources.list && \
    echo 'deb http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse' | tee -a /etc/apt/sources.list && \
    echo 'deb http://security.ubuntu.com/ubuntu xenial-security multiverse' | tee -a /etc/apt/sources.list && \
    cat /etc/apt/sources.list | grep -v "^#" | sort -u > /etc/apt/sources.list.bak && \
    mv -fv /etc/apt/sources.list.bak /etc/apt/sources.list && \
    add-apt-repository -y ppa:ricotz/testing && \
    add-apt-repository -y ppa:gnome3-team/gnome3 && \
    add-apt-repository -y ppa:gnome3-team/gnome3-staging && \
    add-apt-repository -y ppa:pitti/systemd-semaphore && \
    apt-get update -yqq && \
    apt-get upgrade -yqq && \
    export LANG=en_US.UTF-8 && \
    apt-get install -qqy libpulse-dev espeak && \
    apt-cache search --names-only '^(lib)?gstreamer1.0\S*' | sed 's/\(.*\) -.*/\1 /' | grep -iv "Speech"  > dependencies && \
    cat dependencies && \
    apt-get build-dep -y `cat dependencies` && \
    apt-get install -qqy gnome-common \
                        gtk-doc-tools \
                        libgtk-3-dev \
                        libgirepository1.0-dev \
                        yelp-tools \
                        libgladeui-dev \
                        python3-dev \
                        python3-cairo-dev \
                        python3-gi \
                        automake \
                        autopoint \
                        bison \
                        build-essential \
                        byacc \
                        flex \
                        gcc \
                        automake \
                        autoconf \
                        libtool \
                        bison \
                        swig \
                        python-dev \
                        libpulse-dev \
                        gettext \
                        gnome-common \
                        gtk-doc-tools \
                        libgtk-3-dev \
                        libgirepository1.0-dev \
                        python3-gi-cairo \
                        yasm \
                        nasm \
                        bison \
                        flex \
                        libusb-1.0-0-dev \
                        libgudev-1.0-dev \
                        libxv-dev \
                        build-essential \
                        autotools-dev \
                        automake \
                        autoconf \
                        libtool \
                        binutils \
                        autopoint \
                        libxml2-dev \
                        zlib1g-dev \
                        libglib2.0-dev \
                        pkg-config \
                        flex \
                        python \
                        libasound2-dev \
                        libgudev-1.0-dev \
                        libxt-dev \
                        libvorbis-dev \
                        libcdparanoia-dev \
                        libpango1.0-dev \
                        libtheora-dev \
                        libvisual-0.4-dev \
                        iso-codes \
                        libgtk-3-dev \
                        libraw1394-dev \
                        libiec61883-dev \
                        libavc1394-dev \
                        libv4l-dev \
                        libcairo2-dev \
                        libcaca-dev \
                        libspeex-dev \
                        libpng-dev \
                        libshout3-dev \
                        libjpeg-dev \
                        libaa1-dev \
                        libflac-dev \
                        libdv4-dev \
                        libtag1-dev \
                        libwavpack-dev \
                        libpulse-dev \
                        gstreamer1.0* \
                        lame \
                        flac \
                        libfftw3-dev \
                        xvfb \
                        gir1.2-gtk-3.0 \
                        xsltproc \
                        docbook-xml \
                        docbook-xsl \
                        python-libxml2 \
                        sudo \
                        # begin - gst-plugins-bad req
                        libqt4-opengl \
                        libdvdread4 \
                        libdvdnav4 \
                        libllvm3.8 \
                        libsoundtouch-dev \
                        libsoundtouch1 \
                        # For general debugging
                        gdb \
                        strace \
                        lsof \
                        ltrace \
                        graphviz \
                        # end gst-plugins-bad req
                        ubuntu-restricted-extras && \
         apt-get clean && \
         apt-get autoclean -y && \
         apt-get autoremove -y && \
         rm -rf /var/lib/{cache,log}/ && \
         rm -rf /var/lib/apt/lists/*.lz4 /tmp/* /var/tmp/*

# virtualenv stuff
ENV VIRTUALENVWRAPPER_PYTHON '/usr/local/bin/python3'
ENV VIRTUALENVWRAPPER_VIRTUALENV '/usr/local/bin/virtualenv'
ENV VIRTUALENV_WRAPPER_SH '/usr/local/bin/virtualenvwrapper.sh'

# Ensure that Python outputs everything that's printed inside
# the application rather than buffering it.
ENV PYTHONUNBUFFERED 1
ENV PYTHON_VERSION_MAJOR "3"
ENV GSTREAMER "1.0"
ENV USER "pi"
ENV USER_HOME "/home/${UNAME}"
ENV LANGUAGE_ID 1473
ENV GITHUB_BRANCH "master"
ENV GITHUB_REPO_NAME "scarlett_os"
ENV GITHUB_REPO_ORG "bossjones"
ENV PI_HOME "/home/pi"

# /home/pi/dev/bossjones-github/scarlett_os
ENV MAIN_DIR "${PI_HOME}/dev/${GITHUB_REPO_ORG}-github/${GITHUB_REPO_NAME}"

# /home/pi/.virtualenvs/scarlett_os
ENV VIRT_ROOT "${PI_HOME}/.virtualenvs/${GITHUB_REPO_NAME}"

# /home/pi/.virtualenvs/scarlett_os/lib/pkgconfig
ENV PKG_CONFIG_PATH "${PI_HOME}/.virtualenvs/${GITHUB_REPO_NAME}/lib/pkgconfig"

# /home/pi/dev/bossjones-github/scarlett_os/tests/fixtures/.scarlett
ENV SCARLETT_CONFIG "${PI_HOME}/dev/${GITHUB_REPO_ORG}-github/${GITHUB_REPO_NAME}/tests/fixtures/.scarlett"

# /home/pi/dev/bossjones-github/scarlett_os/static/speech/hmm/en_US/hub4wsj_sc_8k
ENV SCARLETT_HMM "${PI_HOME}/dev/${GITHUB_REPO_ORG}-github/${GITHUB_REPO_NAME}/static/speech/hmm/en_US/hub4wsj_sc_8k"

# /home/pi/dev/bossjones-github/scarlett_os/static/speech/lm/1473.lm
ENV SCARLETT_LM "${PI_HOME}/dev/${GITHUB_REPO_ORG}-github/${GITHUB_REPO_NAME}/static/speech/lm/${LANGUAGE_ID}.lm"

# /home/pi/dev/bossjones-github/scarlett_os/static/speech/dict/1473.dic
ENV SCARLETT_DICT "${PI_HOME}/dev/${GITHUB_REPO_ORG}-github/${GITHUB_REPO_NAME}/static/speech/dict/${LANGUAGE_ID}.dic"

# /home/pi/.virtualenvs/repoduce_pytest_mock_issue_84/lib
ENV LD_LIBRARY_PATH "${PI_HOME}/.virtualenvs/${GITHUB_REPO_NAME}/lib"

# /home/pi/.virtualenvs/scarlett_os/lib/gstreamer-1.0
ENV GST_PLUGIN_PATH "${PI_HOME}/.virtualenvs/${GITHUB_REPO_NAME}/lib/gstreamer-${GSTREAMER}"
ENV PYTHON "/usr/local/bin/python3"
ENV PYTHON_VERSION "3.5"
ENV VIRTUALENVWRAPPER_PYTHON "/usr/local/bin/python3"
ENV VIRTUALENVWRAPPER_VIRTUALENV "/usr/local/bin/virtualenv"
ENV VIRTUALENVWRAPPER_SCRIPT "/usr/local/bin/virtualenvwrapper.sh"

# /home/pi/.pythonrc
ENV PYTHONSTARTUP "${USER_HOME}/.pythonrc"
ENV PIP_DOWNLOAD_CACHE "${USER_HOME}/.pip/cache"

# /home/pi/.virtualenvs/scarlett_os
ENV WORKON_HOME "${VIRT_ROOT}"

############################[BEGIN - USER]##############################################
RUN set -xe \
    && useradd -U -d ${PI_HOME} -m -r -G adm,sudo,dip,plugdev,tty,audio ${UNAME} \
    && usermod -a -G ${UNAME} ${UNAME} \
    && mkdir -p ${PI_HOME}/dev/${GITHUB_REPO_ORG}-github \
    && mkdir -p ${PI_HOME}/dev/${GITHUB_REPO_ORG}-github/${GITHUB_REPO_NAME} \
    && mkdir -p ${MAIN_DIR} \
    && chown -hR ${UNAME}:${UNAME} ${MAIN_DIR} \
    && echo 'pi     ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && echo '%pi     ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && cat /etc/sudoers

USER $UNAME

WORKDIR /home/$UNAME

ENV HOME "/home/$UNAME"
############################[END - USER]################################################

# ENV UNAME pacat

# RUN apt-get update \
#  && DEBIAN_FRONTEND=noninteractive apt-get install --yes pulseaudio-utils

# # Set up the user
# RUN export UNAME=$UNAME UID=1000 GID=1000 && \
#     mkdir -p "/home/${UNAME}" && \
#     echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:/home/${UNAME}:/bin/bash" >> /etc/passwd && \
#     echo "${UNAME}:x:${UID}:" >> /etc/group && \
#     mkdir -p /etc/sudoers.d && \
#     echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} && \
#     chmod 0440 /etc/sudoers.d/${UNAME} && \
#     chown ${UID}:${GID} -R /home/${UNAME} && \
#     gpasswd -a ${UNAME} audio

# COPY pulse-client.conf /etc/pulse/client.conf

# USER $UNAME
# ENV HOME /home/pacat

# # run
# CMD ["pacat", "-vvvv", "/dev/urandom"]


# Create a basic .jhbuildrc
RUN echo "import os"                                   > /home/pi/.jhbuildrc && \
    echo "prefix='$PREFIX'"                         >> /home/pi/.jhbuildrc && \
    echo "checkoutroot='$JHBUILD'"                  >> /home/pi/.jhbuildrc && \
    echo "moduleset = 'gnome-world'"                  >> /home/pi/.jhbuildrc && \
    echo "interact = False"                           >> /home/pi/.jhbuildrc && \
    echo "makeargs = '$MAKEFLAGS'"                  >> /home/pi/.jhbuildrc && \
    echo "os.environ['CFLAGS'] = '$CFLAGS'"         >> /home/pi/.jhbuildrc && \
    echo "os.environ['PYTHON'] = 'python$PYTHON_VERSION_MAJOR'"           >> /home/pi/.jhbuildrc && \
    echo "os.environ['GSTREAMER'] = '1.0'"            >> /home/pi/.jhbuildrc && \
    echo "os.environ['ENABLE_PYTHON3'] = 'yes'"       >> /home/pi/.jhbuildrc && \
    echo "os.environ['ENABLE_GTK'] = 'yes'"           >> /home/pi/.jhbuildrc && \
    echo "os.environ['PYTHON_VERSION'] = '$PYTHON_VERSION'"       >> /home/pi/.jhbuildrc && \
    echo "os.environ['CFLAGS'] = '-fPIC -O0 -ggdb -fno-inline -fno-omit-frame-pointer'" >> /home/pi/.jhbuildrc && \
    echo "os.environ['MAKEFLAGS'] = '-j4'"            >> /home/pi/.jhbuildrc && \
    echo "os.environ['PREFIX'] = '$USER_HOME/jhbuild'"   >> /home/pi/.jhbuildrc && \
    echo "os.environ['JHBUILD'] = '$USER_HOME/gnome'"    >> /home/pi/.jhbuildrc && \
    echo "os.environ['PATH'] = '$PREFIX/bin:$PREFIX/sbin:$PATH'" >> /home/pi/.jhbuildrc && \
    echo "os.environ['LD_LIBRARY_PATH'] = '$PREFIX/lib:$LD_LIBRARY_PATH'" >> /home/pi/.jhbuildrc && \
    echo "os.environ['PYTHONPATH'] = '$PREFIX/lib/python$PYTHON_VERSION/site-packages:/usr/lib/python$PYTHON_VERSION/site-packages'" >> /home/pi/.jhbuildrc && \
    echo "os.environ['PKG_CONFIG_PATH'] = '$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:/usr/lib/pkgconfig'" >> /home/pi/.jhbuildrc && \
    echo "os.environ['XDG_DATA_DIRS'] = '$PREFIX/share:/usr/share'" >> /home/pi/.jhbuildrc && \
    echo "os.environ['XDG_CONFIG_DIRS'] = '$PREFIX/etc/xdg'"        >> /home/pi/.jhbuildrc && \
    echo "os.environ['CC'] = 'gcc'"                                   >> /home/pi/.jhbuildrc && \
    echo "os.environ['WORKON_HOME'] = '$USER_HOME/.virtualenvs'"                           >> /home/pi/.jhbuildrc && \
    echo "os.environ['PROJECT_HOME'] = '$USER_HOME/dev'"                                   >> /home/pi/.jhbuildrc && \
    echo "os.environ['VIRTUALENVWRAPPER_PYTHON'] = '$VIRTUALENVWRAPPER_PYTHON'"                  >> /home/pi/.jhbuildrc && \
    echo "os.environ['VIRTUALENVWRAPPER_VIRTUALENV'] = '$VIRTUALENVWRAPPER_VIRTUALENV'"     >> /home/pi/.jhbuildrc && \
    echo "os.environ['PYTHONSTARTUP'] = '$USER_HOME/.pythonrc'"                              >> /home/pi/.jhbuildrc && \
    echo "os.environ['PIP_DOWNLOAD_CACHE'] = '$USER_HOME/.pip/cache'"                        >> /home/pi/.jhbuildrc && \
    cat /home/pi/.jhbuildrc


# jhbuild
RUN mkdir -p /home/pi/gnome && \

    echo "****************[JHBUILD]****************" && \
    cd /home/pi && \
    if test ! -d /home/pi/jhbuild; then git clone https://github.com/GNOME/jhbuild.git && \
    cd jhbuild; else echo "exists" && cd jhbuild; fi && \
    git checkout 86d958b6778da649b559815c0a0dbe6a5d1a8cd4 && \
    ./autogen.sh --prefix=/usr/local > /dev/null && \
    make > /dev/null && \
    sudo make install > /dev/null && \
    sudo chown pi:pi -R /usr/local/ && \
    chown pi:pi -R /home/pi/jhbuild && \

    echo "****************[GTK-DOC]****************" && \
    cd /home/pi/gnome && \
    git clone https://github.com/GNOME/gtk-doc.git && \
    jhbuild buildone -n gtk-doc && \

    echo "****************[GLIB]****************" && \
    cd /home/pi/gnome && \
    git clone https://github.com/GNOME/glib.git && \
    cd glib && \
    git checkout eaca4f4116801f99e30e42a857559e19a1e6f4ce && \
    jhbuild buildone -n glib && \

    echo "****************[GOBJECT-INTROSPECTION]****************" && \
    cd /home/pi/gnome && \
    git clone https://github.com/GNOME/gobject-introspection.git && \
    cd gobject-introspection && \
    git checkout cee2a4f215d5edf2e27b9964d3cfcb28a9d4941c && \
    jhbuild buildone -n gobject-introspection && \

    echo "****************[PYGOBJECT]****************" && \
    cd /home/pi/gnome && \
    git clone https://github.com/GNOME/pygobject.git && \
    cd /home/pi/gnome && \
    cd pygobject && \
    git checkout fb1b8fa8a67f2c7ea7ad4b53076496a8f2b4afdb && \
    jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild --with-python=python3 > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[GSTREAMER]****************" && \
    cd /home/pi/gnome && \
    curl -L "https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-1.8.2.tar.xz" > gstreamer-1.8.2.tar.xz && \
    tar -xJf gstreamer-1.8.2.tar.xz && \
    cd gstreamer-1.8.2 && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
    jhbuild run make -j4  > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[ORC]****************" && \
    cd /home/pi/gnome && \
    curl -L "https://gstreamer.freedesktop.org/src/orc/orc-0.4.25.tar.xz" > orc-0.4.25.tar.xz && \
    tar -xJf orc-0.4.25.tar.xz && \
    cd orc-0.4.25 && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
    jhbuild run make -j4  > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[GST-PLUGINS-BASE]****************" && \
    cd /home/pi/gnome && \
    curl -L "http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-1.8.2.tar.xz" > gst-plugins-base-1.8.2.tar.xz && \
    tar -xJf gst-plugins-base-1.8.2.tar.xz && \
    cd gst-plugins-base-1.8.2 && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc --with-x > /dev/null && \
    jhbuild run make -j4  > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[GST-PLUGINS-GOOD]****************" && \
    cd /home/pi/gnome && \
    curl -L "http://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-1.8.2.tar.xz" > gst-plugins-good-1.8.2.tar.xz && \
    tar -xJf gst-plugins-good-1.8.2.tar.xz && \
    cd gst-plugins-good-1.8.2 && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc --with-libv4l2 --with-x  > /dev/null && \
    jhbuild run make -j4  > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[GST-PLUGINS-UGLY]****************" && \
    cd /home/pi/gnome && \
    curl -L "http://gstreamer.freedesktop.org/src/gst-plugins-ugly/gst-plugins-ugly-1.8.2.tar.xz" > gst-plugins-ugly-1.8.2.tar.xz && \
    tar -xJf gst-plugins-ugly-1.8.2.tar.xz && \
    cd gst-plugins-ugly-1.8.2 && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
    jhbuild run make -j4  > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[GST-PLUGINS-BAD]****************" && \
    cat /home/pi/jhbuild/bin/gdbus-codegen && \
    sed -i "s,#!python3,#!/usr/bin/python3,g" /home/pi/jhbuild/bin/gdbus-codegen && \
    cat /home/pi/jhbuild/bin/gdbus-codegen && \
    cd /home/pi/gnome && \
    curl -L "http://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-1.8.2.tar.xz" > gst-plugins-bad-1.8.2.tar.xz && \
    tar -xJf gst-plugins-bad-1.8.2.tar.xz && \
    cd gst-plugins-bad-1.8.2 && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
    jhbuild run make -j4  > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[GST-LIBAV]****************" && \
    cd /home/pi/gnome && \
    curl -L "http://gstreamer.freedesktop.org/src/gst-libav/gst-libav-1.8.2.tar.xz" > gst-libav-1.8.2.tar.xz && \
    tar -xJf gst-libav-1.8.2.tar.xz && \
    cd gst-libav-1.8.2 && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
    jhbuild run make -j4  > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[GST-PLUGINS-ESPEAK]****************" && \
    cd $JHBUILD && \
    curl -L "https://github.com/bossjones/bossjones-gst-plugins-espeak-0-4-0/archive/v0.4.1.tar.gz" > gst-plugins-espeak-0.4.0.tar.gz && \
    tar xvf gst-plugins-espeak-0.4.0.tar.gz && \
    rm -rfv gst-plugins-espeak-0.4.0 && \
    mv -fv bossjones-gst-plugins-espeak-0-4-0-0.4.1 gst-plugins-espeak-0.4.0 && \
    cd gst-plugins-espeak-0.4.0 && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
    jhbuild run make > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[SPHINXBASE]****************" && \
    cd $JHBUILD && \
    git clone https://github.com/cmusphinx/sphinxbase.git && \
    cd sphinxbase && \
    git checkout 74370799d5b53afc5b5b94a22f5eff9cb9907b97 && \
    cd $JHBUILD/sphinxbase && \
    jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild > /dev/null && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
    jhbuild run make clean all > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[POCKETSPHINX]****************" && \
    cd $JHBUILD && \
    git clone https://github.com/cmusphinx/pocketsphinx.git && \
    cd pocketsphinx && \
    git checkout 68ef5dc6d48d791a747026cd43cc6940a9e19f69 && \
    jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild > /dev/null && \
    jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
    jhbuild run make clean all > /dev/null && \
    jhbuild run make install > /dev/null && \

    echo "****************[GDBINIT]****************" && \
    sudo zcat /usr/share/doc/python3.5/gdbinit.gz > /home/pi/.gdbinit && \
    sudo chown pi:pi /home/pi/.gdbinit && \

    echo "****************[GSTREAMER-COMPLETION]****************" && \
    curl -L 'https://raw.githubusercontent.com/drothlis/gstreamer/bash-completion-master/tools/gstreamer-completion' | sudo tee -a /etc/bash_completion.d/gstreamer-completion && \
    sudo chown root:root /etc/bash_completion.d/gstreamer-completion



# Overlay the root filesystem from this repo
COPY ./container/root /

RUN goss -g /tests/goss.jhbuild.yaml validate --retry-timeout 30s --sleep 1s

# NOTE: intentionally NOT using s6 init as the entrypoint
# This would prevent container debugging if any of those service crash
CMD ["/bin/bash", "/run.sh"]
