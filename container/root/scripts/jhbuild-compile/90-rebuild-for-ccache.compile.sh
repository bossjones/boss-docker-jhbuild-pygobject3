#!/usr/bin/env bash

echo "****************[GTK-DOC]****************" && \
cd /home/pi/gnome && \
jhbuild buildone -f -n gtk-doc && \

echo "****************[GLIB]****************" && \
cd /home/pi/gnome && \
cd glib && \
jhbuild buildone -f -n glib && \

echo "****************[GOBJECT-INTROSPECTION]****************" && \
cd /home/pi/gnome && \
cd gobject-introspection && \
jhbuild buildone -f -n gobject-introspection && \

echo "****************[PYGOBJECT]****************" && \
cd /home/pi/gnome && \
cd /home/pi/gnome && \
cd pygobject && \
jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild --with-python=$(which python3) > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[GSTREAMER]****************" && \
cd /home/pi/gnome && \
cd gstreamer-1.8.2 && \
jhbuild run ./configure --enable-doc-installation=no --prefix=/home/pi/jhbuild > /dev/null && \
jhbuild run make -j4  > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[ORC]****************" && \
cd /home/pi/gnome && \
cd orc-0.4.25 && \
jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
jhbuild run make -j4  > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[GST-PLUGINS-BASE]****************" && \
cd /home/pi/gnome && \
cd gst-plugins-base-1.8.2 && \
jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc --with-x > /dev/null && \
jhbuild run make -j4  > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[GST-PLUGINS-GOOD]****************" && \
cd /home/pi/gnome && \
cd gst-plugins-good-1.8.2 && \
jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc --with-libv4l2 --with-x  > /dev/null && \
jhbuild run make -j4  > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[GST-PLUGINS-UGLY]****************" && \
cd /home/pi/gnome && \
cd gst-plugins-ugly-1.8.2 && \
jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
jhbuild run make -j4  > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[GST-PLUGINS-BAD]****************" && \
cat /home/pi/jhbuild/bin/gdbus-codegen && \
cd /home/pi/gnome && \
cd gst-plugins-bad-1.8.2 && \
jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
jhbuild run make -j4  > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[GST-LIBAV]****************" && \
cd /home/pi/gnome && \
cd gst-libav-1.8.2 && \
jhbuild run ./configure --prefix=/home/pi/jhbuild --enable-orc  > /dev/null && \
jhbuild run make -j4  > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[GST-PLUGINS-ESPEAK]****************" && \
cd $JHBUILD && \
cd gst-plugins-espeak-0.4.0 && \
jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
jhbuild run make > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[SPHINXBASE]****************" && \
cd $JHBUILD && \
cd sphinxbase && \
cd $JHBUILD/sphinxbase && \
jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild > /dev/null && \
jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
jhbuild run make clean all > /dev/null && \
jhbuild run make install > /dev/null && \

echo "****************[POCKETSPHINX]****************" && \
cd $JHBUILD && \
cd pocketsphinx && \
jhbuild run ./autogen.sh --prefix=/home/pi/jhbuild > /dev/null && \
jhbuild run ./configure --prefix=/home/pi/jhbuild > /dev/null && \
jhbuild run make clean all > /dev/null && \
jhbuild run make install > /dev/null
