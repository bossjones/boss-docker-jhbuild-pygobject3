# boss-docker-gnome-pygobject-gtk3-gst-cmusphinx-jhbuild

Gnome x Jhbuild x PyGObject x Cmusphinx x Gtk+3 in 🐳

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


# Order of operations

```
jhbuild_pygobject3_1  | [init] no run.d scripts
jhbuild_pygobject3_1  | [run] starting process manager
jhbuild_pygobject3_1  | [s6-init] making user provided files available at /var/run/s6/etc...exited 0.
jhbuild_pygobject3_1  | [s6-init] ensuring user provided files have correct perms...exited 0.
jhbuild_pygobject3_1  | [fix-attrs.d] applying ownership & permissions fixes...
jhbuild_pygobject3_1  | [fix-attrs.d] done.
jhbuild_pygobject3_1  | [cont-init.d] executing container initialization scripts...
jhbuild_pygobject3_1  | [cont-init.d] 00-init-ssh: executing...
jhbuild_pygobject3_1  | [cont-init.d] 00-init-ssh: exited 0.
jhbuild_pygobject3_1  | [cont-init.d] done.
jhbuild_pygobject3_1  | [services.d] starting services
jhbuild_pygobject3_1  | [services.d] done.
```
