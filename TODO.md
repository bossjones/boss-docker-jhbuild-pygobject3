1. `File error: open /tests/tests/goss.d/s6/*.yaml: no such file or directory`
2. `/home/pi/.local/bin/env-setup: 14: /home/pi/.local/bin/env-setup: cannot create /run/user/1000/env/HOME: Permission denied`
3. Fix for `/usr/bin/install: cannot stat './html/*.sgml': No such file or directory` requires:

```
# source: https://github.com/bbidulock/icewm/issues/100

[@Code7R](https://github.com/code7r) I added dependencies to README.md. You can go ahead and update the INSTALL and INSTALL.cmakebuild files. The autoconf/automake version checks for the tools and libraries required to compile from the tarball; however, some additional tools are required to build from git. One is linuxdoc-tools (for sgml2html). The html help files are included in the tarball release so there is no need for ./configure to have it to install from tarball release. Another one is xorg-mkfontdir which is required by the install-theme.sh script but unnecessary I believe for building from tarball, even though ./configure checks for the mkfondir command. Not sure about cmake. I suppose I could check for a .git directory and then invoke checks for sgml2html and markdown in configure.ac when it exists.

We are a bout 141 commits away from 1.3.12, so I was thinking of releaseing a 1.3.13 (but I don't like the 13 number, so I might skip to 1.3.14). Is there anything outstanding that should be addressed before release?
```

4. errors via `sudo /etc/cont-init.d/50-init-dgoss`

```
cp: cannot create regular file '/artifacts/gnome/glib/.git/objects/pack/pack-11cd34536a93d5ba8cbd4813ebe4cbe827f8bf88.idx': Permission denied
cp: cannot create regular file '/artifacts/gnome/glib/.git/objects/pack/pack-11cd34536a93d5ba8cbd4813ebe4cbe827f8bf88.pack': Permission denied
cp: cannot create regular file '/artifacts/gnome/pygobject/.git/objects/pack/pack-a5c97689a4eb2982fdf48d9e748e39f764f56239.idx': Permission denied
cp: cannot create regular file '/artifacts/gnome/pygobject/.git/objects/pack/pack-a5c97689a4eb2982fdf48d9e748e39f764f56239.pack': Permission denied
cp: cannot create regular file '/artifacts/gnome/sphinxbase/.git/objects/pack/pack-496a2ffbea9ab18897df1412185a035c4fcbf584.pack': Permission denied
cp: cannot create regular file '/artifacts/gnome/sphinxbase/.git/objects/pack/pack-496a2ffbea9ab18897df1412185a035c4fcbf584.idx': Permission denied
^C
[pi@ce2b1e277563 cont-init.d] $
```
