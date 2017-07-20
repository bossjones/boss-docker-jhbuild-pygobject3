FROM bossjones/boss-docker-python3:latest
MAINTAINER Malcolm Jones <bossjones@theblacktonystark.com>

# Prepare packaging environment
ENV DEBIAN_FRONTEND noninteractive

# build-arg are acceptable
# eg. docker build --build-arg var=xxx
ARG SCARLETT_ENABLE_SSHD
ARG SCARLETT_ENABLE_DBUS
ARG SCARLETT_BUILD_GNOME
ARG TRAVIS_CI

# metadata
ARG CONTAINER_VERSION
ARG GIT_BRANCH
ARG GIT_SHA

ENV SCARLETT_ENABLE_SSHD ${SCARLETT_ENABLE_SSHD:-0}
ENV SCARLETT_ENABLE_DBUS ${SCARLETT_ENABLE_DBUS:-'true'}
ENV SCARLETT_BUILD_GNOME ${SCARLETT_BUILD_GNOME:-'true'}
ENV TRAVIS_CI ${TRAVIS_CI:-'true'}

RUN echo "SCARLETT_ENABLE_SSHD: ${SCARLETT_ENABLE_SSHD}"
RUN echo "SCARLETT_ENABLE_DBUS: ${SCARLETT_ENABLE_DBUS}"
RUN echo "SCARLETT_BUILD_GNOME: ${SCARLETT_BUILD_GNOME}"
RUN echo "TRAVIS_CI: ${TRAVIS_CI}"

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
# So, to prevent services from being started automatically when you install packages with dpkg, apt, etc., just do this (as root):
# RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d

# make apt use ipv4 instead of ipv6 ( faster resolution )
RUN sed -i "s@^#precedence ::ffff:0:0/96  100@precedence ::ffff:0:0/96  100@" /etc/gai.conf

# Install language pack before setting env vars to utf-8
RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y \
 	language-pack-en-base && \
  apt-get clean && \
  apt-get autoclean -y && \
  apt-get autoremove -y && \
  rm -rf /var/lib/{cache,log}/ && \
  rm -rf /var/lib/apt/lists/*.lz4 /tmp/* /var/tmp/*

# # Ensure UTF-8 lang and locale
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# ENV TERM="xterm" \
#     LANG="C.UTF-8" \
#     LC_ALL="C.UTF-8"

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:/usr/local/sbin:$PATH

# lets install apt-fast
RUN set -x \
    apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:saiarcot895/myppa && \
    apt-get update && \
    echo "apt-fast apt-fast/maxdownloads string 5" | debconf-set-selections; \
    echo "apt-fast apt-fast/dlflag boolean true" | debconf-set-selections; \
    echo "apt-fast apt-fast/aptmanager string apt-get" | debconf-set-selections; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-fast && \
    # sed -i'' "/^_DOWNLOADER=/ s/-m0/-m0 \
    # --quiet \
    # --console-log-level=error \
    # --show-console-readout=false \
    # --summary-interval=10 \
    # --enable-rpc/" /etc/apt-fast.conf && \
    # sed -i "/^_DOWNLOADER=/ s/-m0/-m0 --quiet --console-log-level=error --show-console-readout=false --summary-interval=10 --enable-rpc --on-download-stop=apt-fast-progress/" /etc/apt-fast.conf && \
    apt-fast update && \
    # now that apt-fast is setup, lets clean everything in this layer
    apt-fast autoremove -y && \
    # now clean regular apt-get stuff
    apt-get clean && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{cache,log}/ && \
    rm -rf /var/lib/apt/lists/*.lz4 /tmp/* /var/tmp/*

# this is what we need to sed
# _DOWNLOADER='aria2c -c -j ${_MAXNUM} -x ${_MAXNUM} -s ${_MAXNUM} --min-split-size=1M -i ${DLLIST} --connect-timeout=600 --timeout=600 -m0'

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.

# FIXME: DO NOT SET env var USER
ENV UNAME "pi"
ENV NOT_ROOT_USER "pi"

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
ENV MAKEFLAGS "-j4 V=1"

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

ENV PYTHON "python3"
ENV TERM "xterm-256color"
ENV PACKAGES "python3-gi python3-gi-cairo"
ENV CC gcc

# NOTE: Couple other things to install for future, like valgrind etc
# source: https://github.com/avranju/docker-linux-dev-image/blob/master/Dockerfile.template
# RUN apt-get clean && \
#     apt-get update && \
#     apt-get install -y \
#         software-properties-common \
#         python2.7 \
#         curl \
#         build-essential \
#         libcurl4-openssl-dev \
#         git \
#         cmake \
#         libssl-dev \
#         uuid-dev \
#         valgrind \
#         libglib2.0-dev \
#         gdb \
#         gdbserver \
#         openssh-server


# FIXME: required for jhbuild( sudo apt-get install docbook-xsl build-essential git-core python-libxml2 )
# source: https://wiki.gnome.org/HowDoI/Jhbuild

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
    apt-fast update -yqq && \
    apt-fast upgrade -yqq && \
    export LANG=en_US.UTF-8 && \
    apt-fast install -qqy libpulse-dev espeak && \
    apt-cache search --names-only '^(lib)?gstreamer1.0\S*' | sed 's/\(.*\) -.*/\1 /' | grep -iv "Speech"  > dependencies && \
    cat dependencies && \
    apt-fast build-dep -y `cat dependencies` && \
    apt-fast install -qqy gnome-common \
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
                        yelp-xsl \
                        docbook-xsl \
                        docbook-xsl-doc-html \
                        python-libxslt1 \
                        libxslt1-dev \
                        graphviz \
                        openssh-server \
                        # optimize compiling
                        gperf \
                        bc \
                        ccache \
                        file \
                        rsync \
                        # vim for debugging
                        # vim for debugging
                        vim \
                        source-highlight \
                        fortune \
                        # end gst-plugins-bad req
                        ubuntu-restricted-extras && \
    apt-fast update && \
    # now that apt-fast is setup, lets clean everything in this layer
    apt-fast autoremove -y && \
    # now clean regular apt-get stuff
    apt-get clean && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{cache,log}/ && \
    rm -rf /var/lib/apt/lists/*.lz4 /tmp/* /var/tmp/*


##########################################################
# needed to fix *.html issues
##########################################################
RUN apt-fast update -y && \
    export LANG=en_US.UTF-8 && \
    apt-fast install -y asciidoctor \
                         libghc-cmark-prof \
                         libghc-markdown-prof \
                         libhtml-wikiconverter-markdown-perl \
                         libmarkdown2-dev \
                         libpod-markdown-perl \
                         libsmdev-dev \
                         libsoldout1-dev \
                         libtext-markdown-discount-perl \
                         libxft2-dbg \
                         linuxdoc-tools \
                         linuxdoc-tools-info \
                         linuxdoc-tools-latex \
                         linuxdoc-tools-text \
                         markdown \
                         python-html2text \
                         python-markdown \
                         python-mistune \
                         python3-html2text \
                         python3-markdown \
                         python3-misaka \
                         # specifics gtk-doc
                         docbook-utils \
                         docbook-xsl \
                         docbook-simple \
                         docbook-to-man \
                         docbook-dsssl \
                         jade \
                         python3-mistune && \
    apt-fast update && \
    # now that apt-fast is setup, lets clean everything in this layer
    apt-fast autoremove -y && \
    # now clean regular apt-get stuff
    apt-get clean && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{cache,log}/ && \
    rm -rf /var/lib/apt/lists/*.lz4 /tmp/* /var/tmp/*

# source: https://docs.docker.com/engine/examples/running_ssh_service/

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd \
    && sed -i -r 's/.?UseDNS\syes/UseDNS no/' /etc/ssh/sshd_config \
    && sed -i -r 's/.?PasswordAuthentication.+/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i -r 's/.?ChallengeResponseAuthentication.+/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# NOTE: It's an example of how to pass environment variables when running a Dockerized SSHD service.
# NOTE: SSHD scrubs the environment, therefore ENV variables contained in Dockerfile must be pushed to
# /etc/profile in order for them to be available.
# source: https://stackoverflow.com/questions/36292317/why-set-visible-now-in-etc-profile
ENV NOTVISIBLE "in users profile"
RUN echo 'export VISIBLE=now' >> /etc/profile

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

# Vagrant pub key for development
ENV USER_SSH_PUBKEY "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"

# Configure runtime directory
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# source: https://github.com/jakelee8/dockerfiles/blob/b1f7fd4520ae3e1b7e9ccebf2b07381a4069cc00/images/steam/steam-ubuntu16.10/Dockerfile
ENV XDG_RUNTIME_DIR=/run/user/1000
# ENV XDG_RUNTIME_DIR=/run/pi/1000

# Source: https://github.com/ambakshi/dockerfiles/blob/09a05ceab3b5a93c974783ad27a8a6301f3c4ca2/devbox/debian8/Dockerfile
RUN echo "[ \$UID -eq 0 ] && PS1='\[\e[31m\]\h:\w#\[\e[m\] ' || PS1='[\[\033[32m\]\u@\h\[\033[00m\] \[\033[36m\]\W\[\033[31m\]\$(__git_ps1)\[\033[00m\]] \$ '"  | tee /etc/bash_completion.d/prompt

############################[BEGIN - USER]##############################################
# FIXME: investigate secure_path: http://manpages.ubuntu.com/manpages/zesty/man5/sudoers.5.html
# NOTE: umask 077 -> allow read, write, and execute permission for the file's owner, but prohibit read, write, and execute permission for everyone else
# NOTE: The file mode creation mask is initialized to this value. If not specified, the mask will be initialized to 022.
# Source: http://manpages.ubuntu.com/manpages/xenial/man8/useradd.8.html
# FIXME: Look at this guy: https://hub.docker.com/r/radmas/mtc-plus-fpm/~/dockerfile/
RUN set -xe \
    && useradd -U -d ${PI_HOME} -m -r -G adm,sudo,dip,plugdev,tty,audio ${UNAME} \
    && usermod -a -G ${UNAME} -s /bin/bash -u 1000 ${UNAME} \
    && groupmod -g 1000 ${UNAME} \
    && mkdir -p ${PI_HOME}/dev/${GITHUB_REPO_ORG}-github \
    && mkdir -p ${PI_HOME}/dev/${GITHUB_REPO_ORG}-github/${GITHUB_REPO_NAME} \
    && mkdir -p ${MAIN_DIR} \
    && ( mkdir ${PI_HOME}/.ssh \
        && chmod og-rwx ${PI_HOME}/.ssh \
        && echo "${USER_SSH_PUBKEY}" \
            > ${PI_HOME}/.ssh/authorized_keys \
    ) \
    && chown -hR ${UNAME}:${UNAME} ${MAIN_DIR} \
    && echo 'pi     ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && echo '%pi     ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && cat /etc/sudoers \
    && echo 'pi:raspberry' | chpasswd \
    && mkdir -p "$XDG_RUNTIME_DIR" \
    && chown -R pi:pi "$XDG_RUNTIME_DIR" \
    && chmod -R 0700 "$XDG_RUNTIME_DIR"

# FIXME: Note this line here breaks permissions due to umask 077 running as root instead of pi user
# FIXME: removing for now, 7/20/2017
# && ( \
#     umask 077 \
#     && mkdir ${PI_HOME}/.ssh \
#     && echo "${USER_SSH_PUBKEY}" \
#         > ${PI_HOME}/.ssh/authorized_keys \
# ) \

# Prepare git to use ssh-agent, ssh keys for adobe-platform; ignore interactive knownhosts questions from ssh
# - For automated building with private repos only accessible by ssh
#
# ********************* ROOT ***********************************************
RUN mkdir -p /root/.ssh && chmod og-rwx /root/.ssh && \
    echo "Host * " > /root/.ssh/config && \
    echo "StrictHostKeyChecking no " >> /root/.ssh/config && \
    echo "UserKnownHostsFile=/dev/null" >> /root/.ssh/config

# Prepare git to use ssh-agent, ssh keys for adobe-platform; ignore interactive knownhosts questions from ssh
# - For automated building with private repos only accessible by ssh
#
# ********************* PI USER ********************************************
RUN echo "Host * " > ${PI_HOME}/.ssh/config && \
    echo "StrictHostKeyChecking no " >> ${PI_HOME}/.ssh/config && \
    echo "UserKnownHostsFile=/dev/null" >> ${PI_HOME}/.ssh/config

# source: https://github.com/just-containers/s6-overlay
# FIXME: For now, `s6-overlay` doesn't support
# running it with a user different than `root`,
# so consequently Dockerfile `USER`
# directive is not supported (except `USER root` of course ;P).
# FIXME: I DISABLED THIS 6/23/2017 # USER $UNAME

WORKDIR /home/$UNAME

ENV HOME "/home/$UNAME"
# ENV DISPLAY :1
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
    echo "module_autogenargs['gtk-doc'] = 'PYTHON=/usr/bin/python3'" >> /home/pi/.jhbuildrc && \
    echo "os.environ['CFLAGS'] = '$CFLAGS'"         >> /home/pi/.jhbuildrc && \
    echo "os.environ['PYTHON'] = 'python$PYTHON_VERSION_MAJOR'"           >> /home/pi/.jhbuildrc && \
    echo "os.environ['GSTREAMER'] = '1.0'"            >> /home/pi/.jhbuildrc && \
    echo "os.environ['ENABLE_PYTHON3'] = 'yes'"       >> /home/pi/.jhbuildrc && \
    echo "os.environ['ENABLE_GTK'] = 'yes'"           >> /home/pi/.jhbuildrc && \
    echo "os.environ['PYTHON_VERSION'] = '$PYTHON_VERSION'"       >> /home/pi/.jhbuildrc && \
    echo "os.environ['CFLAGS'] = '-fPIC -O0 -ggdb -fno-inline -fno-omit-frame-pointer'" >> /home/pi/.jhbuildrc && \
    echo "os.environ['MAKEFLAGS'] = '-j4 V=1'"            >> /home/pi/.jhbuildrc && \
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


# # jhbuild
# RUN mkdir -p /home/pi/gnome && \

#     echo "****************[JHBUILD]****************" && \
#     cd /home/pi && \
#     if test ! -d /home/pi/jhbuild; then git clone https://github.com/GNOME/jhbuild.git && \
#     cd jhbuild; else echo "exists" && cd jhbuild; fi && \
#     git checkout 86d958b6778da649b559815c0a0dbe6a5d1a8cd4 && \
#     ./autogen.sh --prefix=/usr/local > /dev/null && \
#     make > /dev/null && \
#     sudo make install > /dev/null && \
#     sudo chown pi:pi -R /usr/local/ && \
#     chown pi:pi -R /home/pi/jhbuild && \

#     echo "****************[GTK-DOC]****************" && \
#     cd /home/pi/gnome && \
#     git clone https://github.com/GNOME/gtk-doc.git && \
#     jhbuild buildone -n gtk-doc && \

#     echo "****************[GLIB]****************" && \
#     cd /home/pi/gnome && \
#     git clone https://github.com/GNOME/glib.git && \
#     cd glib && \
#     git checkout eaca4f4116801f99e30e42a857559e19a1e6f4ce && \
#     jhbuild buildone -n glib && \

#     echo "****************[GOBJECT-INTROSPECTION]****************" && \
#     cd /home/pi/gnome && \
#     git clone https://github.com/GNOME/gobject-introspection.git && \
#     cd gobject-introspection && \
#     git checkout cee2a4f215d5edf2e27b9964d3cfcb28a9d4941c && \
#     jhbuild buildone -n gobject-introspection && \

#     echo "****************[PYGOBJECT]****************" && \
#     cd /home/pi/gnome && \
#     git clone https://github.com/GNOME/pygobject.git && \
#     cd /home/pi/gnome && \
#     cd pygobject && \
#     git checkout fb1b8fa8a67f2c7ea7ad4b53076496a8f2b4afdb && \
#     jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild --with-python=$(which python3) > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[GSTREAMER]****************" && \
#     cd /home/pi/gnome && \
#     curl -L "https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-1.8.2.tar.xz" > gstreamer-1.8.2.tar.xz && \
#     tar -xJf gstreamer-1.8.2.tar.xz && \
#     cd gstreamer-1.8.2 && \
#     jhbuild run ./configure --enable-doc-installation=no --prefix=/home/pi/jhbuild > /dev/null && \
#     jhbuild run make -j4  > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[ORC]****************" && \
#     cd /home/pi/gnome && \
#     curl -L "https://gstreamer.freedesktop.org/src/orc/orc-0.4.25.tar.xz" > orc-0.4.25.tar.xz && \
#     tar -xJf orc-0.4.25.tar.xz && \
#     cd orc-0.4.25 && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
#     jhbuild run make -j4  > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[GST-PLUGINS-BASE]****************" && \
#     cd /home/pi/gnome && \
#     curl -L "http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-1.8.2.tar.xz" > gst-plugins-base-1.8.2.tar.xz && \
#     tar -xJf gst-plugins-base-1.8.2.tar.xz && \
#     cd gst-plugins-base-1.8.2 && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc --with-x > /dev/null && \
#     jhbuild run make -j4  > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[GST-PLUGINS-GOOD]****************" && \
#     cd /home/pi/gnome && \
#     curl -L "http://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-1.8.2.tar.xz" > gst-plugins-good-1.8.2.tar.xz && \
#     tar -xJf gst-plugins-good-1.8.2.tar.xz && \
#     cd gst-plugins-good-1.8.2 && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc --with-libv4l2 --with-x  > /dev/null && \
#     jhbuild run make -j4  > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[GST-PLUGINS-UGLY]****************" && \
#     cd /home/pi/gnome && \
#     curl -L "http://gstreamer.freedesktop.org/src/gst-plugins-ugly/gst-plugins-ugly-1.8.2.tar.xz" > gst-plugins-ugly-1.8.2.tar.xz && \
#     tar -xJf gst-plugins-ugly-1.8.2.tar.xz && \
#     cd gst-plugins-ugly-1.8.2 && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
#     jhbuild run make -j4  > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[GST-PLUGINS-BAD]****************" && \
#     cat /home/pi/jhbuild/bin/gdbus-codegen && \
#     export BOSSJONES_PATH_TO_PYTHON=$(which python3) && \
#     sed -i "s,#!python3,#!/usr/bin/python3,g" /home/pi/jhbuild/bin/gdbus-codegen && \
#     cat /home/pi/jhbuild/bin/gdbus-codegen && \
#     cd /home/pi/gnome && \
#     curl -L "http://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-1.8.2.tar.xz" > gst-plugins-bad-1.8.2.tar.xz && \
#     tar -xJf gst-plugins-bad-1.8.2.tar.xz && \
#     cd gst-plugins-bad-1.8.2 && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
#     jhbuild run make -j4  > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[GST-LIBAV]****************" && \
#     cd /home/pi/gnome && \
#     curl -L "http://gstreamer.freedesktop.org/src/gst-libav/gst-libav-1.8.2.tar.xz" > gst-libav-1.8.2.tar.xz && \
#     tar -xJf gst-libav-1.8.2.tar.xz && \
#     cd gst-libav-1.8.2 && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
#     jhbuild run make -j4  > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[GST-PLUGINS-ESPEAK]****************" && \
#     cd $JHBUILD && \
#     curl -L "https://github.com/bossjones/bossjones-gst-plugins-espeak-0-4-0/archive/v0.4.1.tar.gz" > gst-plugins-espeak-0.4.0.tar.gz && \
#     tar xvf gst-plugins-espeak-0.4.0.tar.gz && \
#     rm -rfv gst-plugins-espeak-0.4.0 && \
#     mv -fv bossjones-gst-plugins-espeak-0-4-0-0.4.1 gst-plugins-espeak-0.4.0 && \
#     cd gst-plugins-espeak-0.4.0 && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
#     jhbuild run make > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[SPHINXBASE]****************" && \
#     cd $JHBUILD && \
#     git clone https://github.com/cmusphinx/sphinxbase.git && \
#     cd sphinxbase && \
#     git checkout 74370799d5b53afc5b5b94a22f5eff9cb9907b97 && \
#     cd $JHBUILD/sphinxbase && \
#     jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild > /dev/null && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
#     jhbuild run make clean all > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[POCKETSPHINX]****************" && \
#     cd $JHBUILD && \
#     git clone https://github.com/cmusphinx/pocketsphinx.git && \
#     cd pocketsphinx && \
#     git checkout 68ef5dc6d48d791a747026cd43cc6940a9e19f69 && \
#     jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild > /dev/null && \
#     jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
#     jhbuild run make clean all > /dev/null && \
#     jhbuild run make install > /dev/null && \

#     echo "****************[GDBINIT]****************" && \
#     sudo zcat /usr/share/doc/python3.5/gdbinit.gz > /home/pi/.gdbinit && \
#     sudo chown pi:pi /home/pi/.gdbinit && \

#     echo "****************[GSTREAMER-COMPLETION]****************" && \
#     curl -L 'https://raw.githubusercontent.com/drothlis/gstreamer/bash-completion-master/tools/gstreamer-completion' | sudo tee -a /etc/bash_completion.d/gstreamer-completion && \
#     sudo chown root:root /etc/bash_completion.d/gstreamer-completion

# Expose port for ssh
EXPOSE 22

# Overlay the root filesystem from this repo
COPY ./container/root /

# Copy over dotfiles repo, we'll use this later on to init a bunch of thing
COPY ./dotfiles /dotfiles

RUN mkdir -p /home/pi/.local/bin \
    && cp -a /env-setup /home/pi/.local/bin/env-setup \
    && chmod +x /home/pi/.local/bin/env-setup

# NOTE: This should get around any docker permission issues we normally have
RUN cp -a /scripts/compile_jhbuild_and_deps.sh /home/pi/.local/bin/compile_jhbuild_and_deps.sh \
    && chmod +x /home/pi/.local/bin/compile_jhbuild_and_deps.sh \
    && chown pi:pi /home/pi/.local/bin/compile_jhbuild_and_deps.sh

# NOTE: Add dynenv script
RUN cp -a /scripts/with-dynenv /usr/local/bin/with-dynenv \
    && chmod +x /usr/local/bin/with-dynenv \
    && chown pi:pi /usr/local/bin/with-dynenv

# TODO: Need this ccache
# FIXME: This needs to be duplicated in the env-setup script, etc
ENV CCACHE_DIR /ccache

# source: https://wiki.gnome.org/Projects/Jhbuild/Dependencies/Debian#Debian_Stretch_.28testing.29
# TODO: before building should help with some macro issues
# FIXME: This needs to be duplicated in the env-setup script, etc
# FIXME: When ACLOCAL_FLAGS is defined we get: aclocal: error: couldn't open directory '/home/pi/jhbuild/share/aclocal': No such file or directory
# FIXME: We can probably just make the folder, but not worth it at the moment, when we can reduce build time we can try again
# /home/pi/jhbuild/share/aclocal
# ENV ACLOCAL_FLAGS "-I ${PREFIX}/share/aclocal"

# FIXME: Do we need to add this to jhbuildrc?
# os.environ['LDFLAGS'] = "-L" + prefix + "/lib" (in .jhbuildrc) helps if libtool picks up the wrong static libraries.

# TODO: ccache.conf
RUN mkdir -p /ccache && \
    echo "max_size = 5.0G" > /ccache/ccache.conf && \
    chown -R ${UNAME}:${UNAME} /ccache

# NOTE: Temp run install as pi user
USER $UNAME

RUN bash /prep-pi.sh
# Install jhbuild stuff
RUN bash /home/pi/.local/bin/compile_jhbuild_and_deps.sh

RUN pip install --user powerline-status && \
    git config --global core.editor "vim" && \
    git config --global push.default simple && \
    git config --global color.ui true

# NOTE: Return to root user when finished
USER root

RUN bash /prep-pi.sh

# NOTE: Prepare XDG_RUNTIME_DIR and everything else
# we need to run our scripts correctly
RUN bash /scripts/write_xdg_dir_init.sh "pi"
RUN bash /scripts/write_xdg_dir_init.sh "root"

# Make sure the ruby2.2 packages are installed (Debian)
RUN add-apt-repository -y ppa:brightbox/ruby-ng && \
    apt-fast update -yqq && \
    export LANG=en_US.UTF-8 && \
    apt-fast install -qqy ruby2.2 ruby2.2-dev && \
    # now that apt-fast is setup, lets clean everything in this layer
    apt-fast autoremove -y && \
    # now clean regular apt-get stuff
    apt-get clean && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{cache,log}/ && \
    rm -rf /var/lib/apt/lists/*.lz4 /tmp/* /var/tmp/*

# Install powerline deps
# source: https://hub.docker.com/r/namredips/docker-dev/~/dockerfile/
RUN apt-fast update -yqq && \
    export LANG=en_US.UTF-8 && \
    apt-fast install -y autoconf automake libtool autotools-dev build-essential checkinstall bc ncurses-dev ncurses-term powerline python3-powerline fonts-powerline && \
    # now that apt-fast is setup, lets clean everything in this layer
    apt-fast autoremove -y && \
    # now clean regular apt-get stuff
    apt-get clean && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{cache,log}/ && \
    rm -rf /var/lib/apt/lists/*.lz4 /tmp/* /var/tmp/*

# RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
# RUN vim +PluginInstall +qall

# TODO: bash_it stuff will go here
# RUN bash /scripts/setup_pi_user_bash_it_and_powerline.sh

# install bash_it and bats
RUN mkdir -p /home/pi/.tmp && \
    chown pi:pi -R /home/pi/.tmp && \
    cd /home/pi/.tmp && \
    git clone --depth=1 https://github.com/Bash-it/bash-it.git /home/pi/.bash_it && \
    /home/pi/.bash_it/install.sh --silent --no-modify-config && \
    git clone --depth 1 https://github.com/sstephenson/bats.git /home/pi/.tmp/bats && \
    /home/pi/.tmp/bats/install.sh /usr/local && \
    chown pi:pi -R /usr/local && \
    chown -R pi:pi /home/pi \
    && \

    # install powerline
    # source: https://github.com/adidenko/powerline
    # source: https://ubuntu-mate.community/t/installing-powerline-as-quickly-as-possible/5381
    mkdir -p /home/pi/.tmp && \
    chown pi:pi -R /home/pi/.tmp && \
    cd /home/pi/.tmp && \
    git clone https://github.com/powerline/fonts.git /home/pi/dev/powerline-fonts \
    && wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf \
    && wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf \
    && mkdir -p /home/pi/.fonts \
    && mv PowerlineSymbols.otf /home/pi/.fonts/ \
    && fc-cache -vf /home/pi/.fonts/ \
    && mkdir -p /home/pi/.config/fontconfig/conf.d/ \
    && mv 10-powerline-symbols.conf /home/pi/.config/fontconfig/conf.d/ \
    && touch /home/pi/.screenrc \
    && sed -i '1i term screen-256color' /home/pi/.screenrc \
    && git clone https://github.com/adidenko/powerline /home/pi/.config/powerline \
    && chown -R pi:pi /home/pi \
    && \

    # rubygem defaults
    cp -f /dotfiles/gemrc /home/pi/.gemrc \
    && chmod 0644 /home/pi/.gemrc \
    && chown pi:pi /home/pi/.gemrc \
    && \

    # pythonrc defaults
    cp -f /dotfiles/pythonrc /home/pi/.pythonrc \
    && chmod 0644 /home/pi/.pythonrc \
    && chown pi:pi /home/pi/.pythonrc

# RUN pip3 install --upgrade pip
# RUN pip3 install ipython
# RUN pip3 install flake8
# RUN pip3 install pylint

# NOTE: Add proper .profile and .bashrc files
RUN cp -f /dotfiles/profile /home/pi/.profile \
    && chmod 0644 /home/pi/.profile \
    && chown pi:pi /home/pi/.profile \

    && cp -f /dotfiles/bash_profile /home/pi/.bash_profile \
    && chmod 0644 /home/pi/.bash_profile \
    && chown pi:pi /home/pi/.bash_profile \

    && cp -f /dotfiles/bashrc /home/pi/.bashrc \
    && chmod 0644 /home/pi/.bashrc \
    && chown pi:pi /home/pi/.bashrc \

    && cp -a /dotfiles/bash.functions.d/. /home/pi/bash.functions.d/ \
    && chown pi:pi -R /home/pi/bash.functions.d/ \

    && touch /home/pi/.bash_history \
    && chown pi:pi /home/pi/.bash_history \
    && chmod 0600 /home/pi/.bash_history


# -rw-------  1 root root   22 Jul 17 16:55 .bash_history

# RUN goss -g /tests/goss.jhbuild.yaml validate --retry-timeout 30s --sleep 1s

# NOTE: intentionally NOT using s6 init as the entrypoint
# This would prevent container debugging if any of those service crash

# FIXME: Do we need this??
# PYTHONIOENCODING="UTF-8"
# UMASK=002
# EDGE=0
# source: https://github.com/hurricanehrndz/docker-containers/blob/64fe4f2f0975587a00d180330b19e0aa7596581f/headphones/Dockerfile

RUN mkdir -p /artifacts && sudo chown -R pi:pi /artifacts && \
    ls -lta /artifacts

CMD ["/bin/bash", "/run.sh"]

