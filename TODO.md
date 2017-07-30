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

5. re: farstream-0.2: FTBFS: mv: cannot stat 'html/index.sgml': No such file or directory (Debian Bug report logs - #822387)

https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=822387


6. `execline-startup` is meant to be used as a login shell. System administrators should manually add `/etc/execline-startup` to the `/etc/shells` file.


```
grep -q '^/etc/execline-startup' /etc/shells || sed -i '/#.*/a \
/etc/execline-startup' /etc/shells
```

```

# For example, this file is consulted by chsh to determine whether an unprivileged user may change the login shell for her own account. If the command name is not listed, the user will be denied of change.

# testing
|2.2.3|   Malcolms-MBP-3 in ~
[pi@84864eb8ad6f ~] $ sed '/#.*/a \
> /etc/execline-startup' /etc/shells
# /etc/shells: valid login shells
/etc/execline-startup
/bin/sh
/bin/dash
/bin/bash
/bin/rbash
````

7. To get execline-startup working, did the following manually inside container:

a. `cd /scripts`

b. `chmod +x /scripts/*`

c. `bash -x ./write_pi_dotfile_execline-loginshell.sh`

d. `bash -x write_pi_dotfile_execline-shell.sh`

e. `grep -q '^/etc/execline-startup' /etc/shells || sed -i '/#.*/a \
/etc/execline-startup' /etc/shells`

f. `chmod +x /home/pi/.execline-loginshell /home/pi/.execline-shell`

g. how to test afterwards

```
d478bc28d79d:~# sudo su - pi /etc/execline-startup
multisubstitute: usage: see http://skarnet.org/software/execline/multisubstitute.html
/etc/execline-startup: line 54: export: `/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin': not a valid identifier
s6-envdir: usage: s6-envdir [ -I | -i ] [ -n ] [ -f ] [ -c nullchar ] dir prog...
/etc/execline-startup: line 59: export: `/etc/execline-shell': not a valid identifier
fdblock: usage: fdblock [ -n ] fd prog...
fdblock: usage: fdblock [ -n ] fd prog...
fdblock: usage: fdblock [ -n ] fd prog...
foreground: warning: unable to spawn s6-applyuidgid: Permission denied
foreground: fatal: unable to wait for s6-applyuidgid: No child process
d478bc28d79d:~#
```

h. More all dependencies into other repo before this, named https://github.com/bossjones/boss-docker-base-gtk3-deps ... this will include all user related stuff, `apt-fast installs`, `folder setup, etc`. Then we'll have boss-docker-jhbuild inherit from that to speed up builds. It'll take care of compiling only. We can even do jhbuild compiling stuff in different dockerfile and save the jhbuild folder with it. Then, when needed, we call that file down, which will move the `gnome` folder and `jhbuild` folder to a volume mount, then we have boss-docker-jhbuild-pygobject mount it into place and commit it to a layer. Finally we push that up and have scarlett_os pull that guy down. Should help speed up builds a bit in multiple places.
