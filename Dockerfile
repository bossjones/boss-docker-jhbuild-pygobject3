FROM bossjones/boss-docker-base-gtk3-deps:0.1.0
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

# Build-time metadata as defined at http://label-schema.org
# ARG BUILD_DATE
# ARG VCS_REF
# ARG VERSION
LABEL \
  org.label-schema.name="boss-docker-jhbuild-pygobject3" \
  org.label-schema.description="Gnome x Jhbuild x PyGObject x Cmusphinx x Gtk+3 in Docker" \
  org.label-schema.url="https://github.com/bossjones/boss-docker-jhbuild-pygobject3/" \
  org.label-schema.vcs-ref=$GIT_SHA \
  org.label-schema.vcs-url="https://github.com/bossjones/boss-docker-jhbuild-pygobject3" \
  org.label-schema.vendor="Tonydark Labs" \
  org.label-schema.version=$CONTAINER_VERSION \
  org.label-schema.schema-version=$CONTAINER_VERSION

ENV SCARLETT_ENABLE_SSHD ${SCARLETT_ENABLE_SSHD:-0}
ENV SCARLETT_ENABLE_DBUS ${SCARLETT_ENABLE_DBUS:-'true'}
ENV SCARLETT_BUILD_GNOME ${SCARLETT_BUILD_GNOME:-'true'}
ENV TRAVIS_CI ${TRAVIS_CI:-'true'}

# # Ensure UTF-8 lang and locale
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:/usr/local/sbin:$PATH

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

# NOTE: It's an example of how to pass environment variables when running a Dockerized SSHD service.
# NOTE: SSHD scrubs the environment, therefore ENV variables contained in Dockerfile must be pushed to
# /etc/profile in order for them to be available.
# source: https://stackoverflow.com/questions/36292317/why-set-visible-now-in-etc-profile
ENV NOTVISIBLE "in users profile"
# DISABLED # RUN echo 'export VISIBLE=now' >> /etc/profile

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

# Expose port for ssh
EXPOSE 22

# Overlay the root filesystem from this repo
COPY ./container/root /

# Copy over dotfiles repo, we'll use this later on to init a bunch of thing
COPY ./dotfiles /dotfiles

WORKDIR /home/$UNAME

ENV HOME "/home/$UNAME"

ENV CCACHE_DIR /ccache

# NOTE: Temp run install as pi user
USER $UNAME

# FIXME: required for jhbuild( sudo apt-get install docbook-xsl build-essential git-core python-libxml2 )
# source: https://wiki.gnome.org/HowDoI/Jhbuild
RUN \
    echo "SCARLETT_ENABLE_SSHD: ${SCARLETT_ENABLE_SSHD}" && \
    echo "SCARLETT_ENABLE_DBUS: ${SCARLETT_ENABLE_DBUS}" && \
    echo "SCARLETT_BUILD_GNOME: ${SCARLETT_BUILD_GNOME}" && \
    echo "TRAVIS_CI: ${TRAVIS_CI}" && \
    bash /prep-pi.sh && \
    bash /home/pi/.local/bin/compile_jhbuild_and_deps.sh

# NOTE: Return to root user when finished
USER root

# NOTE: Prepare XDG_RUNTIME_DIR and everything else
# we need to run our scripts correctly
RUN bash /prep-pi.sh && \
    bash /scripts/write_xdg_dir_init.sh "pi" && \
    bash /scripts/write_xdg_dir_init.sh "root"; \

    mkdir -p /artifacts && sudo chown -R pi:pi /artifacts && \
    ls -lta /artifacts

CMD ["/bin/bash", "/run.sh"]

