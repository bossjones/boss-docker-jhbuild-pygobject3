# boss-docker-gnome-pygobject-gtk3-gst-cmusphinx-jhbuild

[![Build Status](https://travis-ci.org/bossjones/boss-docker-jhbuild-pygobject3.svg?branch=master)](https://travis-ci.org/bossjones/boss-docker-jhbuild-pygobject3)

NOTE: This is a prereq for `scarlett_os`. It makes some strong assumptions about how you plan on running jhbuild, and should mainly just run on CI systems.

Docker container that installs an jhbuild environment that has the following:

1. Python3
2. Jhbuild
3. Glib
4. Gobject-introspection
5. Gstreamer
6. Gst-Espeak-Plugin
7. Gtk3
8. Pocketsphinx/Sphinxbase


# Build

`docker build -t docker-gnome-pygobject-gtk3-gst-cmusphinx-jhbuild .`



# Links

- https://github.com/search?q=execlineb+sshd&type=Code&utf8=%E2%9C%93
