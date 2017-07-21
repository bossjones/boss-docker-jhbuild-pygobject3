# When to use exec?

`source: `

`exec` replaces the current program in the current process, without forking a new process. It is not something you would use in every script you write, but it comes in handy on occasion. Here are some scenarios I have used it;

1. We want the user to run a specific application program without access to the shell. We could change the sign-in program in /etc/passwd, but maybe we want environment setting to be used from start-up files. So, in (say) .profile, the last statement says something like:

`exec appln-program`

so now there is no shell to go back to. Even if appln-program crashes, the end-user cannot get to a shell, because it is not there - the exec replaced it.

2. We want to use a different shell to the one in /etc/passwd. Stupid as it may seem, some sites do not allow users to alter their sign-in shell. One site I know had everyone start with csh, and everyone just put into their .login (csh start-up file) a call to ksh. While that worked, it left a stray csh process running, and the logout was two stage which could get confusing. So we changed it to exec ksh which just replaced the c-shell program with the korn shell, and made everything simpler (there are other issues with this, such as the fact that the ksh is not a login-shell).

3. Just to save processes. If we call prog1 -> prog2 -> prog3 -> prog4 etc. and never go back, then make each call an exec. It saves resources (not much, admittedly, unless repeated) and makes shutdown simplier.
You have obviously seen exec used somewhere, perhaps if you showed the code that's bugging you we could justify its use.

Edit: I realised that my answer above is incomplete. There are two uses of exec in shells like ksh and bash - used for opening file descriptors. Here are some examples:

```
exec 3< thisfile          # open "thisfile" for reading on file descriptor 3
exec 4> thatfile          # open "thatfile" for writing on file descriptor 4
exec 8<> tother           # open "tother" for reading and writing on fd 8
exec 6>> other            # open "other" for appending on file descriptor 6
exec 5<&0                 # copy read file descriptor 0 onto file descriptor 5
exec 7>&4                 # copy write file descriptor 4 onto 7
exec 3<&-                 # close the read file descriptor 3
exec 6>&-                 # close the write file descriptor 6
```

Note that spacing is very important here. If you place a space between the fd number and the redirection symbol then exec reverts to the original meaning:


`exec 3 < thisfile       # oops, overwrite the current program with command "3"`

There are several ways you can use these, on ksh use read -u or print -u, on bash, for example:

```
read <&3
echo stuff >&4
```

------------------------

# Another s6 example to deal with (exec s6-setuidgid $USER)

**https://forums.plex.tv/discussion/255288/setting-locale-to-utf8**

You can enter the Docker image and edit the run script instead. Its here: `/etc/services.d/plex/run`
Add two lines to the script so it looks like the following:

```
#!/usr/bin/with-contenv bash

echo "Starting Plex Media Server."
home="$(echo ~plex)"
export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR:-${home}/Library/Application Support}"
export PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver
export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6
export PLEX_MEDIA_SERVER_INFO_DEVICE=docker
export LC_ALL="C"
export LANG="C"

if [ ! -d "${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR}" ]; then
  /bin/mkdir -p "${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR}"
  chown plex:plex "${PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR}"
fi

exec s6-setuidgid plex /bin/sh -c 'LD_LIBRARY_PATH=/usr/lib/plexmediaserver /usr/lib/plexmediaserver/Plex\ Media\ Server'
```

And restart the docker image and see if it fixes it.



# example (docker-beets/root/etc/services.d/beets/run)

**source: https://github.com/linuxserver/docker-beets/blob/e2114dd6082f9f688b7d448a49c2be1cadf5719b/root/etc/services.d/beets/run**

```
#!/usr/bin/with-contenv bash
umask 022

exec \
	s6-setuidgid abc beet web
```

### Executing initialization And/Or finalization tasks

After fixing attributes (through `/etc/fix-attrs.d/`) and just before starting user provided services up (through `/etc/services.d`) our overlay will execute all the scripts found in `/etc/cont-init.d`, for example:

[`/etc/cont-init.d/02-confd-onetime`](https://github.com/just-containers/nginx-loadbalancer/blob/master/rootfs/etc/cont-init.d/02-confd-onetime):

```
#!/usr/bin/execlineb -P

with-contenv
s6-envuidgid nginx
multisubstitute
{
  import -u -D0 UID
  import -u -D0 GID
  import -u CONFD_PREFIX
  define CONFD_CHECK_CMD "/usr/sbin/nginx -t -c {{ .src }}"
}
confd --onetime --prefix="${CONFD_PREFIX}" --tmpl-uid="${UID}" --tmpl-gid="${GID}" --tmpl-src="/etc/nginx/nginx.conf.tmpl" --tmpl-dest="/etc/nginx/nginx.conf" --tmpl-check-cmd="${CONFD_CHECK_CMD}" etcd

```

### [](#writing-a-service-script)

# Caching docker images during builds example


## [Caching] Example 1
**source: https://github.com/travis-ci/travis-ci/issues/5358**

Im doing something like this for 1.13 for images on amazon ECR, but you get the idea.

```
before_install:
- sudo apt-get update && sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-engine
- export REPO=$AWS_ACCOUNT.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_NAME
- docker pull $(REPO):$(TRAVIS_BRANCH)
script:
- docker build --cache-from $(REPO):$(TRAVIS_BRANCH) -t $(REPO):$(TRAVIS_COMMIT) .

```

Works like a charm.


## [Caching] Example 2

I'm always explicitly tagging my images. Maybe that will help.

```
docker build -t test1 .
docker tag test1 namespace/test1:latest
docker push namespace/test1:latest
```


## [Caching] Example 3 ( bump the version of docker up)

FWIW until Travis updates their version, you can update the version of Docker your Travis build is using, e.g. [like this](https://gist.github.com/dylanscott/ea6cff4900c50f4e85a58c01477e9473). Note that I still needed to list the docker service under the services key in .travis.yml, otherwise I was having issues running the docker cli without sudo.

I can confirm that the `--cache-from` feature in 1.13 works wonderfully. It's saving us a ton of build time on a large node app since we avoid `yarn install`ing every build unless `package.json` changes. It's by far the easiest way to take advantage of the docker layer cache that I've seen. Also if it saves anyone any trouble, FYI `--cache-from` does **not** pull the image in question for you. You need to pull it yourself.


### [Caching] Example 4

https://gist.github.com/marcbachmann/16574ba8c614bb3b78614a351f324b86

### [Caching] Example 5

http://rundef.com/fast-travis-ci-docker-build

-------------------

# Why I Ditched DockerHub's Automated Builds

http://www.mikeheijmans.com/docker/2015/09/18/why-i-ditched-docker-hub-auto-builds/


# travis push docker hub

### Pushing a Docker Image to a Registry

In order to push an image to a registry, one must first authenticate via docker login. The email, username, and password used for login should be stored in the repository settings environment variables, which may be set up through the web or locally via the Travis CLI, e.g.:

```
travis env set DOCKER_USERNAME myusername
travis env set DOCKER_PASSWORD secretsecret
```

Within your .travis.yml prior to attempting a docker push or perhaps before docker pull of a private image, e.g.:

```
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
```

### Branch Based Registry Pushes

To push a particular branch of your repository to a remote registry, use the after_success section of your .travis.yml:

```
after_success:
  - if [ "$TRAVIS_BRANCH" == "master" ]; then
    docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD";
    docker push USER/REPO;
    fi
```


### NOTE: When we move to docker-compose version 2+

```
version: "2"

services:
  jhbuild_pygobject3:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        SCARLETT_ENABLE_SSHD: 0
        SCARLETT_ENABLE_DBUS: 'true'
        SCARLETT_BUILD_GNOME: 'true'
        TRAVIS_CI: 'true'
    environment:
      SERVER_LOG_MINIMAL: 1
      SERVER_APP_NAME: jhbuild-pygobject3-ci
      COMPOSE_PROJECT_NAME: jhbuild-pygobject3-ci
      S6_KILL_FINISH_MAXTIME: 1
      S6_KILL_GRACETIME: 1
      SERVER_WORKER_PROCESSES: 1
      # NOTE: This enables SSHD access inside of the container for dev purposes
      # 1 = false
      # 0 = true
      SCARLETT_ENABLE_SSHD: 0
      SCARLETT_ENABLE_DBUS: 'true'
      SCARLETT_BUILD_GNOME: 'true'
      TRAVIS_CI: 'true'
    stdin_open: true
    tty: true
    volumes:
    - ./container/root/tests/goss.jhbuild.yaml:/goss.jhbuild.yaml
    ports:
    - "2222:22"
```


### execline-shell

```
The execline-shell script:

execline-shell executes $HOME/.execline-shell if available (or /bin/sh otherwise) with the arguments it is given.

Interface:

/etc/execline-shell

- execline-shell transforms itself into ${HOME}/.execline-shell $@.
- ${HOME}/.execline-shell must be readable and executable by the user. It must exec into an interactive shell with $@ as its argument.

Notes:

execline-shell is meant to be used as the SHELL environment variable value. It allows one to specify his favourite shell and shell configuration in any language, since the ${HOME}/.execline-shell file can be any executable program. ${HOME}/.execline-shell can be seen as a portable .whateverrc file.
As an administrator-modifiable configuration file, execline-shell provided in execline's examples/etc/ subdirectory, and should be copied by the administrator to /etc.
```


### execline-startup

```
The execline-startup script:

execline-startup performs some system-specific login initialization,
then executes ${HOME}/.execline-loginshell.

Interface:

/etc/execline-startup

- execline-startup sets the SHELL environment variable to /etc/execline-shell. It then performs some system-specific initialization, and transforms itself into ${HOME}/.execline-loginshell $@ if available (and /etc/execline-shell otherwise).
- ${HOME}/.execline-loginshell must be readable and executable by the user. It must exec into $SHELL $@.

Notes:

execline-startup is an execlineb script; hence, it is readable and modifiable. It is meant to be modified by the system administrator to perform system-specific login-time initialization.
As a modifiable configuration file, execline-startup is provided in execline's examples/etc/ subdirectory, and should be copied by the administrator to /etc.
execline-startup is meant to be used as a login shell. System administrators should manually add /etc/execline-startup to the /etc/shells file. The /etc/execline-startup file itself plays the role of the /etc/profile file, and ${HOME}/.execline-loginshell plays the role of the ${HOME}/.profile file.
```


# docker exec commands to set pi user correctly (7/6/2017 WE NEED TO DO THIS)

- `with-contenv` -  set all the container env vars correctly
- `~/.local/bin/env-setup` - write all env vars to `/run/user/1000/env`. Chown to pi:pi after.


### Detect if jhbuild installed correctly:

```
# Install jhbuild if not done
if [ ! -f "$USER_HOME/.local/bin/jhbuild" ] && [ -f "$USER_HOME/jhbuild/checkout/jhbuild/autogen.sh" ]; then
  cd $USER_HOME/jhbuild/checkout/jhbuild/
  sudo -u "$SUDO_USER" ./autogen.sh --simple-install
  sudo -u "$SUDO_USER" make
  sudo -u "$SUDO_USER" make install
fi
```

### ccache setup?

```
# Configure ccache compiler cache. This shall help speeding up compilation
CCACHE=$(which ccache)
sudo -u "$SUDO_USER" mkdir -p "$USER_HOME/jhbuild/install/bin"
if [ "$CCACHE" ]; then
  for compiler in cc gcc c++ g++; do
    if [ ! -e "$USER_HOME/jhbuild/install/bin/$compiler" ]; then
      sudo -u "$SUDO_USER" ln -s "$CCACHE" "$USER_HOME/jhbuild/install/bin/$compiler"
    fi
  done
fi
```

### ccache env vars need to be set?

*https://wiki.archlinux.org/index.php/ccache*

`export PATH="/usr/lib/ccache/bin/:$PATH"`
`export PATH="/usr/lib/colorgcc/bin/:$PATH"    # As per usual colorgcc installation, leave unchanged (don't add ccache)`
`export CCACHE_PATH="/usr/bin"                 # Tell ccache to only use compilers here`


### history from docker exec

**COMMAND:** `docker exec --user 1000 -i -t bossdockerjhbuildpygobject3_jhbuild_pygobject3_1 bash`

```
[pi@414f388874c0 ~] $ curl -L 'https://raw.githubusercontent.com/dragonmaus/home-old/master/.shrc' > ~/.shrc
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   250  100   250    0     0    498      0 --:--:-- --:--:-- --:--:--   499
[pi@414f388874c0 ~] $ curl -L 'https://raw.githubusercontent.com/dragonmaus/home-old/master/.execline-shell' > ~/.execline-shell
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   130  100   130    0     0    384      0 --:--:-- --:--:-- --:--:--   384
[pi@414f388874c0 ~] $ curl -L 'https://raw.githubusercontent.com/dragonmaus/home-old/master/.execline-loginshell' > ~/.execline-loginshell
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   957  100   957    0     0   3207      0 --:--:-- --:--:-- --:--:--  3211
[pi@414f388874c0 ~] $ cp -a /run/user/1000/env/
CC                            HOME                          PAGER                         PYTHONUNBUFFERED              SERVER_APP_NAME               VIRTUALENVWRAPPER_PYTHON
CFLAGS                        JHBUILD                       PATH                          PYTHON_VERSION                SERVER_LOG_MINIMAL            VIRTUALENVWRAPPER_SCRIPT
CURRENT_DIR                   LANG                          PATH_TO_DOT_VIRTUALENV        PYTHON_VERSION_MAJOR          SERVER_WORKER_PROCESSES       VIRTUALENV_WRAPPER_SH
DEBIAN_FRONTEND               LANGUAGE_ID                   PI_HOME                       S6_BEHAVIOUR_IF_STAGE2_FAILS  SHELL                         VIRTUALENVWRAPPER_VIRTUALENV
EDITOR                        LC_ALL                        PIP_DOWNLOAD_CACHE            S6_KILL_FINISH_MAXTIME        SIGNAL_BUILD_STOP             WORKON_HOME
ENABLE_GTK                    LD_LIBRARY_PATH               PKG_CONFIG_PATH               S6_KILL_GRACETIME             SKIP_ON_TRAVIS                XDG_CACHE_HOME
ENABLE_PYTHON3                LESS                          PREFIX                        S6_VERSION                    TERM                          XDG_CONFIG_DIRS
GITHUB_BRANCH                 LOGNAME                       PROJECT_HOME                  SCARLETT_CONFIG               TRAVIS_CI                     XDG_CONFIG_HOME
GITHUB_REPO_NAME              MAIN_DIR                      PWD                           SCARLETT_DICT                 UNAME                         XDG_DATA_DIRS
GITHUB_REPO_ORG               MAKEFLAGS                     PYTHON                        SCARLETT_ENABLE_DBUS          USER                          XDG_DATA_HOME
GOSS_VERSION                  NOT_ROOT_USER                 PYTHONPATH                    SCARLETT_ENABLE_SSHD          USER_HOME                     XDG_RUNTIME_DIR
GST_PLUGIN_PATH               NOTVISIBLE                    PYTHON_PIP_VERSION            SCARLETT_HMM                  USER_SSH_PUBKEY
GSTREAMER                     PACKAGES                      PYTHONSTARTUP                 SCARLETT_LM                   VIRT_ROOT
[pi@414f388874c0 ~] $ cp -a /run/user/1000/env/
CC                            HOME                          PAGER                         PYTHONUNBUFFERED              SERVER_APP_NAME               VIRTUALENVWRAPPER_PYTHON
CFLAGS                        JHBUILD                       PATH                          PYTHON_VERSION                SERVER_LOG_MINIMAL            VIRTUALENVWRAPPER_SCRIPT
CURRENT_DIR                   LANG                          PATH_TO_DOT_VIRTUALENV        PYTHON_VERSION_MAJOR          SERVER_WORKER_PROCESSES       VIRTUALENV_WRAPPER_SH
DEBIAN_FRONTEND               LANGUAGE_ID                   PI_HOME                       S6_BEHAVIOUR_IF_STAGE2_FAILS  SHELL                         VIRTUALENVWRAPPER_VIRTUALENV
EDITOR                        LC_ALL                        PIP_DOWNLOAD_CACHE            S6_KILL_FINISH_MAXTIME        SIGNAL_BUILD_STOP             WORKON_HOME
ENABLE_GTK                    LD_LIBRARY_PATH               PKG_CONFIG_PATH               S6_KILL_GRACETIME             SKIP_ON_TRAVIS                XDG_CACHE_HOME
ENABLE_PYTHON3                LESS                          PREFIX                        S6_VERSION                    TERM                          XDG_CONFIG_DIRS
GITHUB_BRANCH                 LOGNAME                       PROJECT_HOME                  SCARLETT_CONFIG               TRAVIS_CI                     XDG_CONFIG_HOME
GITHUB_REPO_NAME              MAIN_DIR                      PWD                           SCARLETT_DICT                 UNAME                         XDG_DATA_DIRS
GITHUB_REPO_ORG               MAKEFLAGS                     PYTHON                        SCARLETT_ENABLE_DBUS          USER                          XDG_DATA_HOME
GOSS_VERSION                  NOT_ROOT_USER                 PYTHONPATH                    SCARLETT_ENABLE_SSHD          USER_HOME                     XDG_RUNTIME_DIR
GST_PLUGIN_PATH               NOTVISIBLE                    PYTHON_PIP_VERSION            SCARLETT_HMM                  USER_SSH_PUBKEY
GSTREAMER                     PACKAGES                      PYTHONSTARTUP                 SCARLETT_LM                   VIRT_ROOT
[pi@414f388874c0 ~] $ cp -a /run/user/1000/env ~/.execline-env
[pi@414f388874c0 ~] $

[pi@414f388874c0 ~] $ curl -L 'https://raw.githubusercontent.com/dragonmaus/home-old/master/.logout' > ~/.logout
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100     8  100     8    0     0     21      0 --:--:-- --:--:-- --:--:--    21
[pi@414f388874c0 ~] $ man sudo
[pi@414f388874c0 ~] $ man() {
>     LESS_TERMCAP_md=$'\e[01;31m' \
>     LESS_TERMCAP_me=$'\e[0m' \
>     LESS_TERMCAP_se=$'\e[0m' \
>     LESS_TERMCAP_so=$'\e[01;44;33m' \
>     LESS_TERMCAP_ue=$'\e[0m' \
>     LESS_TERMCAP_us=$'\e[01;32m' \
>     command man "$@"
> }
[pi@414f388874c0 ~] $ man sudo
[pi@414f388874c0 ~] $ man sudo
[pi@414f388874c0 ~] $ vim .shrc
[pi@414f388874c0 ~] $ curl -L 'https://raw.githubusercontent.com/dragonmaus/home-old/master/.profile' > ~/.profile
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   503  100   503    0     0   2274      0 --:--:-- --:--:-- --:--:--  2265
[pi@414f388874c0 ~] $ vim ~/.profile
```

### .logout

```
     -K, --remove-timestamp
                 Similar to the -k option, except that it removes the user's cached credentials entirely and may not be used in conjunction with a command or other option.  This option does not
                 require a password.  Not all security policies support credential caching.
```


### Add this to .functions folder

```
# Add color to man pages
# source: https://wiki.archlinux.org/index.php/Color_output_in_console#man

man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}
```


# find commands for goss testing

### ${HOME}/gnome/* folders

```
[pi@414f388874c0 ~] $ find ./gnome -maxdepth 1 -type d -print
./gnome
./gnome/gstreamer-1.8.2
./gnome/orc-0.4.25
./gnome/glib
./gnome/pygobject
./gnome/sphinxbase
./gnome/gobject-introspection
./gnome/gst-plugins-bad-1.8.2
./gnome/gst-plugins-base-1.8.2
./gnome/gst-plugins-ugly-1.8.2
./gnome/gst-plugins-espeak-0.4.0
./gnome/pocketsphinx
./gnome/gtk-doc
./gnome/gst-plugins-good-1.8.2
./gnome/gst-libav-1.8.2
[pi@414f388874c0 ~] $
```

```
# run this
[pi@414f388874c0 ~] $ for i in $(find ./gnome -maxdepth 1 -type d -print | xargs);do goss a file $i; done
Adding File to './goss.yaml':

/home/pi/gnome:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gstreamer-1.8.2:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/orc-0.4.25:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/glib:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/pygobject:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/sphinxbase:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gobject-introspection:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-bad-1.8.2:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-base-1.8.2:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-ugly-1.8.2:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-espeak-0.4.0:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/pocketsphinx:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gtk-doc:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-good-1.8.2:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-libav-1.8.2:
  exists: true
  mode: "0755"
  size: 4096
  owner: pi
  group: pi
  filetype: directory
  contains: []

```


### Verify autogen.sh exists, that means we at least tried to compile everything*

```
[pi@414f388874c0 ~] $ find ./gnome -name "autogen.sh*" -print
./gnome/gstreamer-1.8.2/autogen.sh
./gnome/orc-0.4.25/autogen.sh
./gnome/glib/autogen.sh
./gnome/pygobject/autogen.sh
./gnome/sphinxbase/autogen.sh
./gnome/gobject-introspection/autogen.sh
./gnome/gst-plugins-bad-1.8.2/autogen.sh
./gnome/gst-plugins-base-1.8.2/autogen.sh
./gnome/gst-plugins-ugly-1.8.2/autogen.sh
./gnome/pocketsphinx/autogen.sh
./gnome/gtk-doc/autogen.sh
./gnome/gst-plugins-good-1.8.2/autogen.sh
./gnome/gst-libav-1.8.2/autogen.sh
[pi@414f388874c0 ~] $

[pi@414f388874c0 ~] $ for i in $(find ./gnome -name "autogen.sh*" -print | xargs);do goss a file $i; done
Adding File to './goss.yaml':

/home/pi/gnome/gstreamer-1.8.2/autogen.sh:
  exists: true
  mode: "0755"
  size: 3201
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/orc-0.4.25/autogen.sh:
  exists: true
  mode: "0755"
  size: 277
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/glib/autogen.sh:
  exists: true
  mode: "0755"
  size: 967
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/pygobject/autogen.sh:
  exists: true
  mode: "0755"
  size: 458
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/sphinxbase/autogen.sh:
  exists: true
  mode: "0755"
  size: 3087
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gobject-introspection/autogen.sh:
  exists: true
  mode: "0755"
  size: 740
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-bad-1.8.2/autogen.sh:
  exists: true
  mode: "0755"
  size: 3225
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-base-1.8.2/autogen.sh:
  exists: true
  mode: "0755"
  size: 3229
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-ugly-1.8.2/autogen.sh:
  exists: true
  mode: "0755"
  size: 3229
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/pocketsphinx/autogen.sh:
  exists: true
  mode: "0755"
  size: 3087
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gtk-doc/autogen.sh:
  exists: true
  mode: "0755"
  size: 434
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-plugins-good-1.8.2/autogen.sh:
  exists: true
  mode: "0755"
  size: 3229
  owner: pi
  group: pi
  filetype: file
  contains: []


Adding File to './goss.yaml':

/home/pi/gnome/gst-libav-1.8.2/autogen.sh:
  exists: true
  mode: "0755"
  size: 3201
  owner: pi
  group: pi
  filetype: file
  contains: []


[pi@414f388874c0 ~] $
```

### find static libraries ".lo" files generated for each jhbuild package type

```
[pi@414f388874c0 ~] $ find ./gnome -maxdepth 1 -type d -print | grep -v "^./gnome$"
./gnome/gstreamer-1.8.2
./gnome/orc-0.4.25
./gnome/glib
./gnome/pygobject
./gnome/sphinxbase
./gnome/gobject-introspection
./gnome/gst-plugins-bad-1.8.2
./gnome/gst-plugins-base-1.8.2
./gnome/gst-plugins-ugly-1.8.2
./gnome/gst-plugins-espeak-0.4.0
./gnome/pocketsphinx
./gnome/gtk-doc
./gnome/gst-plugins-good-1.8.2
./gnome/gst-libav-1.8.2
[pi@414f388874c0 ~] $
```

```
# iterate through list of folders first
for i in $(find ./gnome -maxdepth 1 -type d -print | grep -v "^./gnome$" | xargs); do
  # then do a find in that folder for all .lo files created in the past day
  for j in $(find $i -name "*.lo" -mtime -2 -print | xargs); do
    # goss a file $j; done
    # Test w/ echo for now
    echo $j
  done
done

# actual run
[pi@414f388874c0 ~] $ for i in $(find ./gnome -maxdepth 1 -type d -print | grep -v "^./gnome$" | xargs); do    for j in $(find $i -name "*.lo" -mtime -2 -print | xargs); do      echo $j ;   done ; done

./gnome/gstreamer-1.8.2/libs/gst/controller/libgstcontroller_1.0_la-gstlfocontrolsource.lo
./gnome/gstreamer-1.8.2/libs/gst/controller/libgstcontroller_1.0_la-gstinterpolationcontrolsource.lo
./gnome/gstreamer-1.8.2/libs/gst/controller/libgstcontroller_1.0_la-gsttimedvaluecontrolsource.lo
./gnome/gstreamer-1.8.2/libs/gst/controller/libgstcontroller_1.0_la-gstdirectcontrolbinding.lo
./gnome/gstreamer-1.8.2/libs/gst/controller/libgstcontroller_1.0_la-gsttriggercontrolsource.lo
./gnome/gstreamer-1.8.2/libs/gst/controller/libgstcontroller_1.0_la-gstargbcontrolbinding.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gsttypefindhelper.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstbasetransform.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstflowcombiner.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstcollectpads.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstbitreader.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstdataqueue.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstbasesrc.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstqueuearray.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstadapter.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstbasesink.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstpushsrc.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstbytereader.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstbytewriter.lo
./gnome/gstreamer-1.8.2/libs/gst/base/libgstbase_1.0_la-gstbaseparse.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libgstcheck_1.0_la-gstconsistencychecker.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libgstcheck_1.0_la-gsttestclock.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libgstcheck_1.0_la-gstbufferstraw.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libgstcheck_1.0_la-gstharness.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check_msg.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check_run.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check_log.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check_print.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check_error.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-libcompat.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check_list.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check_pack.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libcheck/libcheckinternal_la-check_str.lo
./gnome/gstreamer-1.8.2/libs/gst/check/libgstcheck_1.0_la-gstcheck.lo
./gnome/gstreamer-1.8.2/libs/gst/net/libgstnet_1.0_la-gstntppacket.lo
./gnome/gstreamer-1.8.2/libs/gst/net/libgstnet_1.0_la-gstnetcontrolmessagemeta.lo
./gnome/gstreamer-1.8.2/libs/gst/net/libgstnet_1.0_la-gstnetaddressmeta.lo
./gnome/gstreamer-1.8.2/libs/gst/net/libgstnet_1.0_la-gstptpclock.lo
./gnome/gstreamer-1.8.2/libs/gst/net/libgstnet_1.0_la-gstnettimeprovider.lo
./gnome/gstreamer-1.8.2/libs/gst/net/libgstnet_1.0_la-gstnetclientclock.lo
./gnome/gstreamer-1.8.2/libs/gst/net/libgstnet_1.0_la-gstnettimepacket.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttaskpool.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstiterator.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstparamspecs.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstutils.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstformat.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstclock.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstcontext.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstdatetime.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttracerutils.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstenumtypes.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttask.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttypefindfactory.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstpoll.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstquark.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstdevicemonitor.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstelementfactory.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstdevice.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstpipeline.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstregistrychunks.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstcontrolbinding.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttracerrecord.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstchildproxy.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsterror.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstmessage.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstbufferlist.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstprotection.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstpreset.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstpluginfeature.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstdeviceprovider.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstmemory.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstvalue.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstbin.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstregistrybinary.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttocsetter.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstparse.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttrace.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstminiobject.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstcapsfeatures.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstatomicqueue.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttracer.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttoc.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstsegment.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gst.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstmeta.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstpluginloader.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstbus.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstobject.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstdebugutils.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstcontrolsource.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstevent.lo
./gnome/gstreamer-1.8.2/gst/parse/libgstparse_la-grammar.tab.lo
./gnome/gstreamer-1.8.2/gst/parse/libgstparse_la-lex.priv_gst_parse_yy.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstsample.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstallocator.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstbufferpool.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttracerfactory.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsturi.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstplugin.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttagsetter.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstcaps.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstghostpad.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstpad.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstbuffer.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstpadtemplate.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstsystemclock.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstelement.lo
./gnome/gstreamer-1.8.2/gst/printf/libgstprintf_la-vasnprintf.lo
./gnome/gstreamer-1.8.2/gst/printf/libgstprintf_la-printf-extension.lo
./gnome/gstreamer-1.8.2/gst/printf/libgstprintf_la-printf-args.lo
./gnome/gstreamer-1.8.2/gst/printf/libgstprintf_la-asnprintf.lo
./gnome/gstreamer-1.8.2/gst/printf/libgstprintf_la-printf-parse.lo
./gnome/gstreamer-1.8.2/gst/printf/libgstprintf_la-printf.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstclock-linreg.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstinfo.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstquery.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttaglist.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gsttypefind.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstregistry.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gststructure.lo
./gnome/gstreamer-1.8.2/gst/libgstreamer_1.0_la-gstdeviceproviderfactory.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstidentity.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstfilesrc.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstsparsefile.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstelements_private.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gsttee.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstfakesink.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstinputselector.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstelements.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstfdsrc.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstoutputselector.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gsttypefindelement.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstcapsfilter.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstvalve.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstfdsink.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstconcat.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstfilesink.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstfunnel.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstqueue.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstdownloadbuffer.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gststreamiddemux.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstfakesrc.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstmultiqueue.lo
./gnome/gstreamer-1.8.2/plugins/elements/libgstcoreelements_la-gstqueue2.lo
./gnome/gstreamer-1.8.2/plugins/tracers/libgstcoretracers_la-gstrusage.lo
./gnome/gstreamer-1.8.2/plugins/tracers/libgstcoretracers_la-gsttracers.lo
./gnome/gstreamer-1.8.2/plugins/tracers/libgstcoretracers_la-gststats.lo
./gnome/gstreamer-1.8.2/plugins/tracers/libgstcoretracers_la-gstlog.lo
./gnome/gstreamer-1.8.2/plugins/tracers/libgstcoretracers_la-gstlatency.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcprogram-altivec.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcmmx.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcprogram-mmx.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orccodemem.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcrules-mmx.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcx86.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcprogram-neon.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcrule.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcbytecode.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcprogram-c.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcmips.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcprogram.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orc.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcrules-neon.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcemulateopcodes.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcexecutor.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcdebug.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orccode.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcfunctions.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcprogram-sse.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcutils.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcpowerpc.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcparse.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcrules-altivec.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcopcodes.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orccpu-x86.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcsse.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcrules-sse.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcprogram-c64x-c.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcx86insn.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcarm.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orconce.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcprogram-mips.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orccompiler.lo
./gnome/orc-0.4.25/orc/liborc_0.4_la-orcrules-mips.lo
./gnome/orc-0.4.25/orc-test/liborc_test_0.4_la-orcarray.lo
./gnome/orc-0.4.25/orc-test/liborc_test_0.4_la-orcprofile.lo
./gnome/orc-0.4.25/orc-test/liborc_test_0.4_la-orctest.lo
./gnome/orc-0.4.25/orc-test/liborc_test_0.4_la-orcrandom.lo
./gnome/pygobject/gi/_gi_la-pygi-list.lo
./gnome/pygobject/gi/_gi_la-pygi-value.lo
./gnome/pygobject/gi/_gi_la-gimodule.lo
./gnome/pygobject/gi/_gi_la-pygi-basictype.lo
./gnome/pygobject/gi/_gi_la-pyginterface.lo
./gnome/pygobject/gi/_gi_la-pygi-array.lo
./gnome/pygobject/gi/_gi_la-pygobject-object.lo
./gnome/pygobject/gi/_gi_la-pygi-foreign.lo
./gnome/pygobject/gi/_gi_la-pygi-signal-closure.lo
./gnome/pygobject/gi/_gi_la-pygi-object.lo
./gnome/pygobject/gi/_gi_la-pygoptioncontext.lo
./gnome/pygobject/gi/_gi_la-pygi-util.lo
./gnome/pygobject/gi/_gi_la-pygi-cache.lo
./gnome/pygobject/gi/_gi_la-pygoptiongroup.lo
./gnome/pygobject/gi/_gi_la-pygi-source.lo
./gnome/pygobject/gi/_gi_la-pygi-property.lo
./gnome/pygobject/gi/_gi_la-pygi-enum-marshal.lo
./gnome/pygobject/gi/_gi_la-pygi-info.lo
./gnome/pygobject/gi/_gi_la-pyglib.lo
./gnome/pygobject/gi/_gi_la-pygi-argument.lo
./gnome/pygobject/gi/_gi_la-pygi-closure.lo
./gnome/pygobject/gi/_gi_la-pygi-struct-marshal.lo
./gnome/pygobject/gi/_gi_la-glibmodule.lo
./gnome/pygobject/gi/_gi_la-pygboxed.lo
./gnome/pygobject/gi/_gi_la-pygtype.lo
./gnome/pygobject/gi/_gi_la-pygi-marshal-cleanup.lo
./gnome/pygobject/gi/_gi_cairo_la-pygi-foreign-cairo.lo
./gnome/pygobject/gi/_gi_la-pygi-invoke.lo
./gnome/pygobject/gi/_gi_la-pygi-error.lo
./gnome/pygobject/gi/_gi_la-pygi-hashtable.lo
./gnome/pygobject/gi/_gi_la-gobjectmodule.lo
./gnome/pygobject/gi/_gi_la-pygpointer.lo
./gnome/pygobject/gi/_gi_la-pygspawn.lo
./gnome/pygobject/gi/_gi_la-pygi-resulttuple.lo
./gnome/pygobject/gi/_gi_la-pygenum.lo
./gnome/pygobject/gi/_gi_la-pygi-repository.lo
./gnome/pygobject/gi/_gi_la-pygi-struct.lo
./gnome/pygobject/gi/_gi_la-pygflags.lo
./gnome/pygobject/gi/_gi_la-pygi-boxed.lo
./gnome/pygobject/gi/_gi_la-pygparamspec.lo
./gnome/pygobject/gi/_gi_la-pygi-ccallback.lo
./gnome/pygobject/gi/_gi_la-pygi-type.lo
./gnome/sphinxbase/swig/python/_sphinxbase_la-sphinxbase_wrap.lo
./gnome/sphinxbase/src/libsphinxbase/util/cmd_ln.lo
./gnome/sphinxbase/src/libsphinxbase/util/err.lo
./gnome/sphinxbase/src/libsphinxbase/util/bio.lo
./gnome/sphinxbase/src/libsphinxbase/util/glist.lo
./gnome/sphinxbase/src/libsphinxbase/util/huff_code.lo
./gnome/sphinxbase/src/libsphinxbase/util/sbthread.lo
./gnome/sphinxbase/src/libsphinxbase/util/priority_queue.lo
./gnome/sphinxbase/src/libsphinxbase/util/slamch.lo
./gnome/sphinxbase/src/libsphinxbase/util/listelem_alloc.lo
./gnome/sphinxbase/src/libsphinxbase/util/dtoa.lo
./gnome/sphinxbase/src/libsphinxbase/util/matrix.lo
./gnome/sphinxbase/src/libsphinxbase/util/mmio.lo
./gnome/sphinxbase/src/libsphinxbase/util/heap.lo
./gnome/sphinxbase/src/libsphinxbase/util/strfuncs.lo
./gnome/sphinxbase/src/libsphinxbase/util/ckd_alloc.lo
./gnome/sphinxbase/src/libsphinxbase/util/case.lo
./gnome/sphinxbase/src/libsphinxbase/util/bitvec.lo
./gnome/sphinxbase/src/libsphinxbase/util/hash_table.lo
./gnome/sphinxbase/src/libsphinxbase/util/f2c_lite.lo
./gnome/sphinxbase/src/libsphinxbase/util/pio.lo
./gnome/sphinxbase/src/libsphinxbase/util/slapack_lite.lo
./gnome/sphinxbase/src/libsphinxbase/util/profile.lo
./gnome/sphinxbase/src/libsphinxbase/util/filename.lo
./gnome/sphinxbase/src/libsphinxbase/util/bitarr.lo
./gnome/sphinxbase/src/libsphinxbase/util/blas_lite.lo
./gnome/sphinxbase/src/libsphinxbase/util/genrand.lo
./gnome/sphinxbase/src/libsphinxbase/util/logmath.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fe_prespch_buf.lo
./gnome/sphinxbase/src/libsphinxbase/fe/yin.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fixlog.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fe_interface.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fe_warp_piecewise_linear.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fe_sigproc.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fe_noise.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fe_warp.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fe_warp_inverse_linear.lo
./gnome/sphinxbase/src/libsphinxbase/fe/fe_warp_affine.lo
./gnome/sphinxbase/src/libsphinxbase/lm/fsg_model.lo
./gnome/sphinxbase/src/libsphinxbase/lm/ngram_model.lo
./gnome/sphinxbase/src/libsphinxbase/lm/ngrams_raw.lo
./gnome/sphinxbase/src/libsphinxbase/lm/jsgf_scanner.lo
./gnome/sphinxbase/src/libsphinxbase/lm/jsgf.lo
./gnome/sphinxbase/src/libsphinxbase/lm/lm_trie_quant.lo
./gnome/sphinxbase/src/libsphinxbase/lm/jsgf_parser.lo
./gnome/sphinxbase/src/libsphinxbase/lm/ngram_model_set.lo
./gnome/sphinxbase/src/libsphinxbase/lm/ngram_model_trie.lo
./gnome/sphinxbase/src/libsphinxbase/lm/lm_trie.lo
./gnome/sphinxbase/src/libsphinxbase/feat/lda.lo
./gnome/sphinxbase/src/libsphinxbase/feat/cmn_prior.lo
./gnome/sphinxbase/src/libsphinxbase/feat/agc.lo
./gnome/sphinxbase/src/libsphinxbase/feat/feat.lo
./gnome/sphinxbase/src/libsphinxbase/feat/cmn.lo
./gnome/sphinxbase/src/libsphinxad/ad_pulse.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/player/libgstplayer_1.0_la-gstplayer-video-renderer.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/player/libgstplayer_1.0_la-gstplayer-media-info.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/player/libgstplayer_1.0_la-gstplayer-visualization.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/player/libgstplayer_1.0_la-gstplayer-video-overlay-video-renderer.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/player/libgstplayer_1.0_la-gstplayer-signal-dispatcher.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/player/libgstplayer_1.0_la-gstplayer-g-main-context-signal-dispatcher.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/player/libgstplayer_1.0_la-gstplayer.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/uridownloader/libgsturidownloader_1.0_la-gstfragment.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/uridownloader/libgsturidownloader_1.0_la-gsturidownloader.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gstmpegvideometa.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-nalutils.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gstvp8rangedecoder.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-parserutils.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gstjpegparser.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gstmpeg4parser.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-vp9utils.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gstmpegvideoparser.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gsth264parser.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gstvp9parser.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-dboolhuff.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gsth265parser.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gstvc1parser.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-gstvp8parser.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/codecparsers/libgstcodecparsers_1.0_la-vp8utils.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/video/libgstbadvideo_1.0_la-gstvideoaggregator.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/basecamerabinsrc/libgstbasecamerabinsrc_1.0_la-gstcamerabin-enum.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/basecamerabinsrc/libgstbasecamerabinsrc_1.0_la-gstcamerabinpreview.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/basecamerabinsrc/libgstbasecamerabinsrc_1.0_la-gstbasecamerasrc.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/adaptivedemux/libgstadaptivedemux_1.0_la-gstadaptivedemux.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/audio/libgstbadaudio_1.0_la-gstaudioaggregator.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/wayland/libgstwayland_1.0_la-wayland.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/mpegts/libgstmpegts_1.0_la-gst-atsc-section.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/mpegts/libgstmpegts_1.0_la-gst-dvb-descriptor.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/mpegts/libgstmpegts_1.0_la-gst-dvb-section.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/mpegts/libgstmpegts_1.0_la-gstmpegtssection.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/mpegts/libgstmpegts_1.0_la-gstmpegts-enumtypes.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/mpegts/libgstmpegts_1.0_la-gstmpegtsdescriptor.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/interfaces/libgstphotography_1.0_la-photography-enumtypes.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/interfaces/libgstphotography_1.0_la-photography.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/base/libgstbadbase_1.0_la-gstaggregator.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglmemory.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglupload.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglbasememory.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglframebuffer.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglwindow.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglsyncmeta.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglshaderstrings.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglformat.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglsl.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglbasefilter.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/x11/libgstgl_x11_la-gstglwindow_x11.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/x11/libgstgl_x11_la-x11_event_source.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/x11/libgstgl_x11_la-gstgldisplay_x11.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/x11/libgstgl_x11_la-gstglcontext_glx.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/egl/libgstgl_egl_la-gstglcontext_egl.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/egl/libgstgl_egl_la-gstgldisplay_egl.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/egl/libgstgl_egl_la-gsteglimagememory.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglshader.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglquery.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstgldisplay.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstgldebug.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglfeature.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglbuffer.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/wayland/libgstgl_wayland_la-wayland_event_source.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/wayland/libgstgl_wayland_la-gstglwindow_wayland_egl.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/wayland/libgstgl_wayland_la-gstgldisplay_wayland.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglviewconvert.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglcontrolbindingproxy.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglapi.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglfilter.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglcolorconvert.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglmemorypbo.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglslstage.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglutils.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglcontext.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstglbufferpool.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/gl/libgstgl_1.0_la-gstgloverlaycompositor.lo
./gnome/gst-plugins-bad-1.8.2/gst-libs/gst/insertbin/libgstinsertbin_1.0_la-gstinsertbin.lo
./gnome/gst-plugins-bad-1.8.2/sys/decklink/libgstdecklink_la-gstdecklinkaudiosrc.lo
./gnome/gst-plugins-bad-1.8.2/sys/decklink/linux/libgstdecklink_la-DeckLinkAPIDispatch.lo
./gnome/gst-plugins-bad-1.8.2/sys/decklink/libgstdecklink_la-gstdecklink.lo
./gnome/gst-plugins-bad-1.8.2/sys/decklink/libgstdecklink_la-gstdecklinkvideosink.lo
./gnome/gst-plugins-bad-1.8.2/sys/decklink/libgstdecklink_la-gstdecklinkvideosrc.lo
./gnome/gst-plugins-bad-1.8.2/sys/decklink/libgstdecklink_la-gstdecklinkaudiosink.lo
./gnome/gst-plugins-bad-1.8.2/sys/shm/libgstshm_la-gstshmsink.lo
./gnome/gst-plugins-bad-1.8.2/sys/shm/libgstshm_la-gstshm.lo
./gnome/gst-plugins-bad-1.8.2/sys/shm/libgstshm_la-shmalloc.lo
./gnome/gst-plugins-bad-1.8.2/sys/shm/libgstshm_la-gstshmsrc.lo
./gnome/gst-plugins-bad-1.8.2/sys/shm/libgstshm_la-shmpipe.lo
./gnome/gst-plugins-bad-1.8.2/sys/bluez/libgstbluez_la-bluez-plugin.lo
./gnome/gst-plugins-bad-1.8.2/sys/bluez/libgstbluez_la-gstavdtputil.lo
./gnome/gst-plugins-bad-1.8.2/sys/bluez/libgstbluez_la-gsta2dpsink.lo
./gnome/gst-plugins-bad-1.8.2/sys/bluez/libgstbluez_la-gstavdtpsrc.lo
./gnome/gst-plugins-bad-1.8.2/sys/bluez/libgstbluez_la-gstavdtpsink.lo
./gnome/gst-plugins-bad-1.8.2/sys/bluez/libgstbluez_la-bluez.lo
./gnome/gst-plugins-bad-1.8.2/sys/vcd/libgstvcdsrc_la-vcdsrc.lo
./gnome/gst-plugins-bad-1.8.2/sys/fbdev/libgstfbdevsink_la-gstfbdevsink.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camsession.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camapplicationinfo.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camresourcemanager.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camutils.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-gstdvb.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-cam.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camswclient.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-dvbbasebin.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camconditionalaccess.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-gstdvbsrc.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camdevice.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camapplication.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-camtransport.lo
./gnome/gst-plugins-bad-1.8.2/sys/dvb/libgstdvb_la-parsechannels.lo
./gnome/gst-plugins-bad-1.8.2/sys/uvch264/libgstuvch264_la-gstuvch264_mjpgdemux.lo
./gnome/gst-plugins-bad-1.8.2/sys/uvch264/libgstuvch264_la-uvc_h264.lo
./gnome/gst-plugins-bad-1.8.2/sys/uvch264/libgstuvch264_la-gstuvch264.lo
./gnome/gst-plugins-bad-1.8.2/sys/uvch264/libgstuvch264_la-gstuvch264_src.lo
./gnome/gst-plugins-bad-1.8.2/tests/examples/gl/gtk/libgstgtkhelper_la-gstgtk.lo
./gnome/gst-plugins-bad-1.8.2/tests/check/elements/libparser_la-parser.lo
./gnome/gst-plugins-bad-1.8.2/gst/stereo/libgststereo_la-gststereo.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-gstvc1parse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-gsth264parse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-gsth265parse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-gsth263parse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-h263parse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-dirac_parse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-gstmpegvideoparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-gstpngparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-gstdiracparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoparsers/libgstvideoparsersbad_la-gstmpeg4videoparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiomixer/libgstaudiomixer_la-tmp-orc.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiomixer/libgstaudiomixer_la-gstaudiointerleave.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiomixer/libgstaudiomixer_la-gstaudiomixer.lo
./gnome/gst-plugins-bad-1.8.2/gst/camerabin2/libgstcamerabin2_la-gstviewfinderbin.lo
./gnome/gst-plugins-bad-1.8.2/gst/camerabin2/libgstcamerabin2_la-gstcamerabin2.lo
./gnome/gst-plugins-bad-1.8.2/gst/camerabin2/libgstcamerabin2_la-camerabingeneral.lo
./gnome/gst-plugins-bad-1.8.2/gst/camerabin2/libgstcamerabin2_la-gstplugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/camerabin2/libgstcamerabin2_la-gstdigitalzoom.lo
./gnome/gst-plugins-bad-1.8.2/gst/camerabin2/libgstcamerabin2_la-gstwrappercamerabinsrc.lo
./gnome/gst-plugins-bad-1.8.2/gst/id3tag/libgstid3tag_la-gstid3mux.lo
./gnome/gst-plugins-bad-1.8.2/gst/id3tag/libgstid3tag_la-id3tag.lo
./gnome/gst-plugins-bad-1.8.2/gst/coloreffects/libgstcoloreffects_la-gstcoloreffects.lo
./gnome/gst-plugins-bad-1.8.2/gst/coloreffects/libgstcoloreffects_la-gstplugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/coloreffects/libgstcoloreffects_la-gstchromahold.lo
./gnome/gst-plugins-bad-1.8.2/gst/netsim/libgstnetsim_la-gstnetsim.lo
./gnome/gst-plugins-bad-1.8.2/gst/freeverb/libgstfreeverb_la-gstfreeverb.lo
./gnome/gst-plugins-bad-1.8.2/gst/adpcmenc/libgstadpcmenc_la-adpcmenc.lo
./gnome/gst-plugins-bad-1.8.2/gst/accurip/libgstaccurip_la-gstaccurip.lo
./gnome/gst-plugins-bad-1.8.2/gst/aiff/libgstaiff_la-aiff.lo
./gnome/gst-plugins-bad-1.8.2/gst/aiff/libgstaiff_la-aiffmux.lo
./gnome/gst-plugins-bad-1.8.2/gst/aiff/libgstaiff_la-aiffparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/yadif/libgstyadif_la-gstyadif.lo
./gnome/gst-plugins-bad-1.8.2/gst/yadif/libgstyadif_la-vf_yadif.lo
./gnome/gst-plugins-bad-1.8.2/gst/yadif/libgstyadif_la-yadif.lo
./gnome/gst-plugins-bad-1.8.2/gst/pnm/libgstpnm_la-gstpnmutils.lo
./gnome/gst-plugins-bad-1.8.2/gst/pnm/libgstpnm_la-gstpnmenc.lo
./gnome/gst-plugins-bad-1.8.2/gst/pnm/libgstpnm_la-gstpnm.lo
./gnome/gst-plugins-bad-1.8.2/gst/pnm/libgstpnm_la-gstpnmdec.lo
./gnome/gst-plugins-bad-1.8.2/gst/librfb/librfb_la-rfbbuffer.lo
./gnome/gst-plugins-bad-1.8.2/gst/librfb/libgstrfbsrc_la-gstrfbsrc.lo
./gnome/gst-plugins-bad-1.8.2/gst/librfb/librfb_la-d3des.lo
./gnome/gst-plugins-bad-1.8.2/gst/librfb/librfb_la-rfbdecoder.lo
./gnome/gst-plugins-bad-1.8.2/gst/dvdspu/libgstdvdspu_la-gstspu-vobsub.lo
./gnome/gst-plugins-bad-1.8.2/gst/dvdspu/libgstdvdspu_la-gstspu-pgs.lo
./gnome/gst-plugins-bad-1.8.2/gst/dvdspu/libgstdvdspu_la-gstspu-vobsub-render.lo
./gnome/gst-plugins-bad-1.8.2/gst/dvdspu/libgstdvdspu_la-gstdvdspu-render.lo
./gnome/gst-plugins-bad-1.8.2/gst/dvdspu/libgstdvdspu_la-gstdvdspu.lo
./gnome/gst-plugins-bad-1.8.2/gst/videofilters/libgstvideofiltersbad_la-gstzebrastripe.lo
./gnome/gst-plugins-bad-1.8.2/gst/videofilters/libgstvideofiltersbad_la-gstvideofiltersbad.lo
./gnome/gst-plugins-bad-1.8.2/gst/videofilters/libgstvideofiltersbad_la-gstvideodiff.lo
./gnome/gst-plugins-bad-1.8.2/gst/videofilters/libgstvideofiltersbad_la-gstscenechange.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-tmp-orc.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-gstexclusion.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-gstchromium.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-gstgaussblur.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-gstsolarize.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-gstplugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-gstburn.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-gstdodge.lo
./gnome/gst-plugins-bad-1.8.2/gst/gaudieffects/libgstgaudieffects_la-gstdilate.lo
./gnome/gst-plugins-bad-1.8.2/gst/gdp/libgstgdp_la-gstgdpdepay.lo
./gnome/gst-plugins-bad-1.8.2/gst/gdp/libgstgdp_la-dataprotocol.lo
./gnome/gst-plugins-bad-1.8.2/gst/gdp/libgstgdp_la-gstgdppay.lo
./gnome/gst-plugins-bad-1.8.2/gst/gdp/libgstgdp_la-gstgdp.lo
./gnome/gst-plugins-bad-1.8.2/gst/asfmux/libgstasfmux_la-gstasfobjects.lo
./gnome/gst-plugins-bad-1.8.2/gst/asfmux/libgstasfmux_la-gstasf.lo
./gnome/gst-plugins-bad-1.8.2/gst/asfmux/libgstasfmux_la-gstrtpasfpay.lo
./gnome/gst-plugins-bad-1.8.2/gst/asfmux/libgstasfmux_la-gstasfparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/asfmux/libgstasfmux_la-gstasfmux.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiovisualizers/libgstaudiovisualizers_la-gstspectrascope.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiovisualizers/libgstaudiovisualizers_la-gstsynaescope.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiovisualizers/libgstaudiovisualizers_la-gstwavescope.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiovisualizers/libgstaudiovisualizers_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiovisualizers/libgstaudiovisualizers_la-gstspacescope.lo
./gnome/gst-plugins-bad-1.8.2/gst/vmnc/libgstvmnc_la-vmncdec.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegdemux/libgstmpegpsdemux_la-gstmpegdemux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegdemux/libgstmpegpsdemux_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegdemux/libgstmpegpsdemux_la-gstpesfilter.lo
./gnome/gst-plugins-bad-1.8.2/gst/ivtc/libgstivtc_la-gstivtc.lo
./gnome/gst-plugins-bad-1.8.2/gst/ivtc/libgstivtc_la-gstcombdetect.lo
./gnome/gst-plugins-bad-1.8.2/gst/debugutils/libgstdebugutilsbad_la-gstdebugspy.lo
./gnome/gst-plugins-bad-1.8.2/gst/debugutils/libgstdebugutilsbad_la-debugutilsbad.lo
./gnome/gst-plugins-bad-1.8.2/gst/debugutils/libgstdebugutilsbad_la-gstcompare.lo
./gnome/gst-plugins-bad-1.8.2/gst/debugutils/libgstdebugutilsbad_la-gsterrorignore.lo
./gnome/gst-plugins-bad-1.8.2/gst/debugutils/libgstdebugutilsbad_la-gstwatchdog.lo
./gnome/gst-plugins-bad-1.8.2/gst/debugutils/libgstdebugutilsbad_la-fpsdisplaysink.lo
./gnome/gst-plugins-bad-1.8.2/gst/debugutils/libgstdebugutilsbad_la-gstchecksumsink.lo
./gnome/gst-plugins-bad-1.8.2/gst/debugutils/libgstdebugutilsbad_la-gstchopmydata.lo
./gnome/gst-plugins-bad-1.8.2/gst/videosignal/libgstvideosignal_la-gstvideoanalyse.lo
./gnome/gst-plugins-bad-1.8.2/gst/videosignal/libgstvideosignal_la-gstsimplevideomark.lo
./gnome/gst-plugins-bad-1.8.2/gst/videosignal/libgstvideosignal_la-gstvideosignal.lo
./gnome/gst-plugins-bad-1.8.2/gst/videosignal/libgstvideosignal_la-gstsimplevideomarkdetect.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstsphere.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstcirclegeometrictransform.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstfisheye.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstcircle.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstgeometrictransform.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstsquare.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstdiffuse.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstperspective.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gsttunnel.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstrotate.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstkaleidoscope.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gsttwirl.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstwaterripple.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstpinch.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gststretch.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-geometricmath.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstbulge.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstmarble.lo
./gnome/gst-plugins-bad-1.8.2/gst/geometrictransform/libgstgeometrictransform_la-gstmirror.lo
./gnome/gst-plugins-bad-1.8.2/gst/segmentclip/libgstsegmentclip_la-gstsegmentclip.lo
./gnome/gst-plugins-bad-1.8.2/gst/segmentclip/libgstsegmentclip_la-gstvideosegmentclip.lo
./gnome/gst-plugins-bad-1.8.2/gst/segmentclip/libgstsegmentclip_la-gstaudiosegmentclip.lo
./gnome/gst-plugins-bad-1.8.2/gst/segmentclip/libgstsegmentclip_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/videoframe_audiolevel/libgstvideoframe_audiolevel_la-gstvideoframe-audiolevel.lo
./gnome/gst-plugins-bad-1.8.2/gst/fieldanalysis/libgstfieldanalysis_la-gstfieldanalysis.lo
./gnome/gst-plugins-bad-1.8.2/gst/fieldanalysis/libgstfieldanalysis_la-tmp-orc.lo
./gnome/gst-plugins-bad-1.8.2/gst/dvbsuboverlay/libgstdvbsuboverlay_la-gstdvbsuboverlay.lo
./gnome/gst-plugins-bad-1.8.2/gst/dvbsuboverlay/libgstdvbsuboverlay_la-dvb-sub.lo
./gnome/gst-plugins-bad-1.8.2/gst/compositor/libgstcompositor_la-blend.lo
./gnome/gst-plugins-bad-1.8.2/gst/compositor/libgstcompositor_la-tmp-orc.lo
./gnome/gst-plugins-bad-1.8.2/gst/compositor/libgstcompositor_la-compositor.lo
./gnome/gst-plugins-bad-1.8.2/gst/bayer/libgstbayer_la-gstrgb2bayer.lo
./gnome/gst-plugins-bad-1.8.2/gst/bayer/libgstbayer_la-gstbayer.lo
./gnome/gst-plugins-bad-1.8.2/gst/bayer/libgstbayer_la-tmp-orc.lo
./gnome/gst-plugins-bad-1.8.2/gst/bayer/libgstbayer_la-gstbayer2rgb.lo
./gnome/gst-plugins-bad-1.8.2/gst/dataurisrc/libgstdataurisrc_la-gstdataurisrc.lo
./gnome/gst-plugins-bad-1.8.2/gst/speed/libgstspeed_la-gstspeed.lo
./gnome/gst-plugins-bad-1.8.2/gst/frei0r/libgstfrei0r_la-gstfrei0rsrc.lo
./gnome/gst-plugins-bad-1.8.2/gst/frei0r/libgstfrei0r_la-gstfrei0rmixer.lo
./gnome/gst-plugins-bad-1.8.2/gst/frei0r/libgstfrei0r_la-gstfrei0r.lo
./gnome/gst-plugins-bad-1.8.2/gst/frei0r/libgstfrei0r_la-gstfrei0rfilter.lo
./gnome/gst-plugins-bad-1.8.2/gst/midi/libgstmidi_la-midiparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/midi/libgstmidi_la-midi.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxftypes.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfaes-bwf.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfmpeg.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfjpeg2000.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfalaw.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfd10.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxful.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfdv-dif.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxf.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfmetadata.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfdemux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfmux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfessence.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfvc3.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfdms1.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfup.lo
./gnome/gst-plugins-bad-1.8.2/gst/mxf/libgstmxf_la-mxfquark.lo
./gnome/gst-plugins-bad-1.8.2/gst/sdp/libgstsdpelem_la-gstsdpelem.lo
./gnome/gst-plugins-bad-1.8.2/gst/sdp/libgstsdpelem_la-gstsdpdemux.lo
./gnome/gst-plugins-bad-1.8.2/gst/onvif/libgstrtponvif_la-gstrtponviftimestamp.lo
./gnome/gst-plugins-bad-1.8.2/gst/onvif/libgstrtponvif_la-gstrtponvif.lo
./gnome/gst-plugins-bad-1.8.2/gst/onvif/libgstrtponvif_la-gstrtponvifparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/pcapparse/libgstpcapparse_la-gstpcapparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/pcapparse/libgstpcapparse_la-gstirtspparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/pcapparse/libgstpcapparse_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/ivfparse/libgstivfparse_la-gstivfparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/inter/libgstinter_la-gstintersubsink.lo
./gnome/gst-plugins-bad-1.8.2/gst/inter/libgstinter_la-gstintervideosrc.lo
./gnome/gst-plugins-bad-1.8.2/gst/inter/libgstinter_la-gstintersubsrc.lo
./gnome/gst-plugins-bad-1.8.2/gst/inter/libgstinter_la-gstintervideosink.lo
./gnome/gst-plugins-bad-1.8.2/gst/inter/libgstinter_la-gstintersurface.lo
./gnome/gst-plugins-bad-1.8.2/gst/inter/libgstinter_la-gstinteraudiosink.lo
./gnome/gst-plugins-bad-1.8.2/gst/inter/libgstinter_la-gstinter.lo
./gnome/gst-plugins-bad-1.8.2/gst/inter/libgstinter_la-gstinteraudiosrc.lo
./gnome/gst-plugins-bad-1.8.2/gst/autoconvert/libgstautoconvert_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/autoconvert/libgstautoconvert_la-gstautoconvert.lo
./gnome/gst-plugins-bad-1.8.2/gst/autoconvert/libgstautoconvert_la-gstautovideoconvert.lo
./gnome/gst-plugins-bad-1.8.2/gst/y4m/libgsty4mdec_la-gsty4mdec.lo
./gnome/gst-plugins-bad-1.8.2/gst/removesilence/libgstremovesilence_la-vad_private.lo
./gnome/gst-plugins-bad-1.8.2/gst/removesilence/libgstremovesilence_la-gstremovesilence.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-rmlt.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-gstsirendec.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-gstsiren.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-gstsirenenc.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-common.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-huffman.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-dct4.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-encoder.lo
./gnome/gst-plugins-bad-1.8.2/gst/siren/libgstsiren_la-decoder.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegpsmux/libgstmpegpsmux_la-psmux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegpsmux/libgstmpegpsmux_la-psmuxstream.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegpsmux/libgstmpegpsmux_la-mpegpsmux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegpsmux/libgstmpegpsmux_la-mpegpsmux_h264.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegpsmux/libgstmpegpsmux_la-mpegpsmux_aac.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsdemux/libgstmpegtsdemux_la-tsdemux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsdemux/libgstmpegtsdemux_la-mpegtspacketizer.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsdemux/libgstmpegtsdemux_la-pesparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsdemux/libgstmpegtsdemux_la-gsttsdemux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsdemux/libgstmpegtsdemux_la-mpegtsbase.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsdemux/libgstmpegtsdemux_la-mpegtsparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiofxbad/libgstaudiofxbad_la-gstaudiofxbad.lo
./gnome/gst-plugins-bad-1.8.2/gst/audiofxbad/libgstaudiofxbad_la-gstaudiochannelmix.lo
./gnome/gst-plugins-bad-1.8.2/gst/jp2kdecimator/libgstjp2kdecimator_la-jp2kcodestream.lo
./gnome/gst-plugins-bad-1.8.2/gst/jp2kdecimator/libgstjp2kdecimator_la-gstjp2kdecimator.lo
./gnome/gst-plugins-bad-1.8.2/gst/rawparse/libgstrawparse_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/gst/rawparse/libgstrawparse_la-gstaudioparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/rawparse/libgstrawparse_la-gstvideoparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/rawparse/libgstrawparse_la-gstrawparse.lo
./gnome/gst-plugins-bad-1.8.2/gst/adpcmdec/libgstadpcmdec_la-adpcmdec.lo
./gnome/gst-plugins-bad-1.8.2/gst/interlace/libgstinterlace_la-gstinterlace.lo
./gnome/gst-plugins-bad-1.8.2/gst/festival/libgstfestival_la-gstfestival.lo
./gnome/gst-plugins-bad-1.8.2/gst/subenc/libgstsubenc_la-gstwebvttenc.lo
./gnome/gst-plugins-bad-1.8.2/gst/subenc/libgstsubenc_la-gstsubenc.lo
./gnome/gst-plugins-bad-1.8.2/gst/subenc/libgstsubenc_la-gstsrtenc.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsmux/libgstmpegtsmux_la-mpegtsmux_aac.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsmux/libgstmpegtsmux_la-mpegtsmux_opus.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsmux/libgstmpegtsmux_la-mpegtsmux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsmux/tsmux/libtsmux_la-tsmuxstream.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsmux/tsmux/libtsmux_la-tsmux.lo
./gnome/gst-plugins-bad-1.8.2/gst/mpegtsmux/libgstmpegtsmux_la-mpegtsmux_ttxt.lo
./gnome/gst-plugins-bad-1.8.2/gst/smooth/libgstsmooth_la-gstsmooth.lo
./gnome/gst-plugins-bad-1.8.2/gst/jpegformat/libgstjpegformat_la-gstjpegformat.lo
./gnome/gst-plugins-bad-1.8.2/gst/jpegformat/libgstjpegformat_la-gstjifmux.lo
./gnome/gst-plugins-bad-1.8.2/gst/jpegformat/libgstjpegformat_la-gstjpegparse.lo
./gnome/gst-plugins-bad-1.8.2/ext/voamrwbenc/libgstvoamrwbenc_la-gstvoamrwb.lo
./gnome/gst-plugins-bad-1.8.2/ext/voamrwbenc/libgstvoamrwbenc_la-gstvoamrwbenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/faad/libgstfaad_la-gstfaad.lo
./gnome/gst-plugins-bad-1.8.2/ext/mplex/libgstmplex_la-gstmplexibitstream.lo
./gnome/gst-plugins-bad-1.8.2/ext/mplex/libgstmplex_la-gstmplex.lo
./gnome/gst-plugins-bad-1.8.2/ext/mplex/libgstmplex_la-gstmplexoutputstream.lo
./gnome/gst-plugins-bad-1.8.2/ext/mplex/libgstmplex_la-gstmplexjob.lo
./gnome/gst-plugins-bad-1.8.2/ext/sndfile/libgstsndfile_la-gstsf.lo
./gnome/gst-plugins-bad-1.8.2/ext/sndfile/libgstsndfile_la-gstsfdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/dash/libgstdashdemux_la-gstmpdparser.lo
./gnome/gst-plugins-bad-1.8.2/ext/dash/libgstdashdemux_la-gstdashdemux.lo
./gnome/gst-plugins-bad-1.8.2/ext/dash/libgstdashdemux_la-gstisoff.lo
./gnome/gst-plugins-bad-1.8.2/ext/dash/libgstdashdemux_la-gstplugin.lo
./gnome/gst-plugins-bad-1.8.2/ext/libde265/libgstlibde265_la-gstlibde265.lo
./gnome/gst-plugins-bad-1.8.2/ext/libde265/libgstlibde265_la-libde265-dec.lo
./gnome/gst-plugins-bad-1.8.2/ext/modplug/libgstmodplug_la-gstmodplug.lo
./gnome/gst-plugins-bad-1.8.2/ext/openal/libgstopenal_la-gstopenal.lo
./gnome/gst-plugins-bad-1.8.2/ext/openal/libgstopenal_la-gstopenalsrc.lo
./gnome/gst-plugins-bad-1.8.2/ext/openal/libgstopenal_la-gstopenalsink.lo
./gnome/gst-plugins-bad-1.8.2/ext/libmms/libgstmms_la-gstmms.lo
./gnome/gst-plugins-bad-1.8.2/ext/sbc/libgstsbc_la-gstsbcenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/sbc/libgstsbc_la-gstsbcdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/sbc/libgstsbc_la-sbc-plugin.lo
./gnome/gst-plugins-bad-1.8.2/ext/spandsp/libgstspandsp_la-gstspandsp.lo
./gnome/gst-plugins-bad-1.8.2/ext/spandsp/libgstspandsp_la-gstdtmfdetect.lo
./gnome/gst-plugins-bad-1.8.2/ext/spandsp/libgstspandsp_la-gsttonegeneratesrc.lo
./gnome/gst-plugins-bad-1.8.2/ext/spandsp/libgstspandsp_la-gstspanplc.lo
./gnome/gst-plugins-bad-1.8.2/ext/zbar/libgstzbar_la-gstzbar.lo
./gnome/gst-plugins-bad-1.8.2/ext/timidity/libgstwildmidi_la-gstwildmidi.lo
./gnome/gst-plugins-bad-1.8.2/ext/gme/libgstgme_la-gstgme.lo
./gnome/gst-plugins-bad-1.8.2/ext/teletextdec/libgstteletextdec_la-gstteletextdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/dts/libgstdtsdec_la-gstdtsdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/hls/libgsthls_la-gsthlsplugin.lo
./gnome/gst-plugins-bad-1.8.2/ext/hls/libgsthls_la-gstm3u8playlist.lo
./gnome/gst-plugins-bad-1.8.2/ext/hls/libgsthls_la-m3u8.lo
./gnome/gst-plugins-bad-1.8.2/ext/hls/libgsthls_la-gsthlsdemux.lo
./gnome/gst-plugins-bad-1.8.2/ext/hls/libgsthls_la-gsthlssink.lo
./gnome/gst-plugins-bad-1.8.2/ext/ofa/libgstofa_la-gstofa.lo
./gnome/gst-plugins-bad-1.8.2/ext/smoothstreaming/libgstsmoothstreaming_la-gstmssdemux.lo
./gnome/gst-plugins-bad-1.8.2/ext/smoothstreaming/libgstsmoothstreaming_la-gstmssmanifest.lo
./gnome/gst-plugins-bad-1.8.2/ext/smoothstreaming/libgstsmoothstreaming_la-gstsmoothstreaming-plugin.lo
./gnome/gst-plugins-bad-1.8.2/ext/chromaprint/libgstchromaprint_la-gstchromaprint.lo
./gnome/gst-plugins-bad-1.8.2/ext/bz2/libgstbz2_la-gstbz2.lo
./gnome/gst-plugins-bad-1.8.2/ext/bz2/libgstbz2_la-gstbz2enc.lo
./gnome/gst-plugins-bad-1.8.2/ext/bz2/libgstbz2_la-gstbz2dec.lo
./gnome/gst-plugins-bad-1.8.2/ext/webp/libgstwebp_la-gstwebpdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/webp/libgstwebp_la-gstwebpenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/webp/libgstwebp_la-gstwebp.lo
./gnome/gst-plugins-bad-1.8.2/ext/curl/libgstcurl_la-gstcurltlssink.lo
./gnome/gst-plugins-bad-1.8.2/ext/curl/libgstcurl_la-gstcurlhttpsink.lo
./gnome/gst-plugins-bad-1.8.2/ext/curl/libgstcurl_la-gstcurlftpsink.lo
./gnome/gst-plugins-bad-1.8.2/ext/curl/libgstcurl_la-gstcurlfilesink.lo
./gnome/gst-plugins-bad-1.8.2/ext/curl/libgstcurl_la-gstcurl.lo
./gnome/gst-plugins-bad-1.8.2/ext/curl/libgstcurl_la-gstcurlbasesink.lo
./gnome/gst-plugins-bad-1.8.2/ext/curl/libgstcurl_la-gstcurlsmtpsink.lo
./gnome/gst-plugins-bad-1.8.2/ext/voaacenc/libgstvoaacenc_la-gstvoaacenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/voaacenc/libgstvoaacenc_la-gstvoaac.lo
./gnome/gst-plugins-bad-1.8.2/ext/openexr/libgstopenexr_la-gstopenexrdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/openexr/libgstopenexr_la-gstopenexr.lo
./gnome/gst-plugins-bad-1.8.2/ext/wayland/libgstwaylandsink_la-wlshmallocator.lo
./gnome/gst-plugins-bad-1.8.2/ext/wayland/libgstwaylandsink_la-gstwaylandsink.lo
./gnome/gst-plugins-bad-1.8.2/ext/wayland/libgstwaylandsink_la-wlvideoformat.lo
./gnome/gst-plugins-bad-1.8.2/ext/wayland/libgstwaylandsink_la-wlwindow.lo
./gnome/gst-plugins-bad-1.8.2/ext/wayland/libgstwaylandsink_la-wldisplay.lo
./gnome/gst-plugins-bad-1.8.2/ext/wayland/libgstwaylandsink_la-scaler-protocol.lo
./gnome/gst-plugins-bad-1.8.2/ext/wayland/libgstwaylandsink_la-wlbuffer.lo
./gnome/gst-plugins-bad-1.8.2/ext/assrender/libgstassrender_la-gstassrender.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstmotioncells.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstskindetect.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstpyramidsegment.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstfacedetect.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstcvsmooth.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstgrabcut.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstretinex.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstedgedetect.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gsthanddetect.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstcvlaplace.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstcverode.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-motioncells_wrapper.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstcvequalizehist.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gsttemplatematch.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-MotionCells.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstopencvutils.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstcvdilateerode.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstfaceblur.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstcvdilate.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstopencv.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstopencvvideofilter.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstdisparity.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gsttextoverlay.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstsegmentation.lo
./gnome/gst-plugins-bad-1.8.2/ext/opencv/libgstopencv_la-gstcvsobel.lo
./gnome/gst-plugins-bad-1.8.2/ext/mimic/libgstmimic_la-gstmimic.lo
./gnome/gst-plugins-bad-1.8.2/ext/mimic/libgstmimic_la-gstmimdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/mimic/libgstmimic_la-gstmimenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/rtmp/libgstrtmp_la-gstrtmp.lo
./gnome/gst-plugins-bad-1.8.2/ext/rtmp/libgstrtmp_la-gstrtmpsrc.lo
./gnome/gst-plugins-bad-1.8.2/ext/rtmp/libgstrtmp_la-gstrtmpsink.lo
./gnome/gst-plugins-bad-1.8.2/ext/schroedinger/libgstschro_la-gstschro.lo
./gnome/gst-plugins-bad-1.8.2/ext/schroedinger/libgstschro_la-gstschrodec.lo
./gnome/gst-plugins-bad-1.8.2/ext/schroedinger/libgstschro_la-gstschroutils.lo
./gnome/gst-plugins-bad-1.8.2/ext/schroedinger/libgstschro_la-gstschroenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/flite/libgstflite_la-gstflitetestsrc.lo
./gnome/gst-plugins-bad-1.8.2/ext/flite/libgstflite_la-gstflite.lo
./gnome/gst-plugins-bad-1.8.2/ext/x265/libgstx265_la-gstx265enc.lo
./gnome/gst-plugins-bad-1.8.2/ext/kate/libgstkate_la-gstkatedec.lo
./gnome/gst-plugins-bad-1.8.2/ext/kate/libgstkate_la-gstkatespu.lo
./gnome/gst-plugins-bad-1.8.2/ext/kate/libgstkate_la-gstkatetag.lo
./gnome/gst-plugins-bad-1.8.2/ext/kate/libgstkate_la-gstkateparse.lo
./gnome/gst-plugins-bad-1.8.2/ext/kate/libgstkate_la-gstkate.lo
./gnome/gst-plugins-bad-1.8.2/ext/kate/libgstkate_la-gstkateenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/kate/libgstkate_la-gstkateutil.lo
./gnome/gst-plugins-bad-1.8.2/ext/fluidsynth/libgstfluidsynthmidi_la-gstfluiddec.lo
./gnome/gst-plugins-bad-1.8.2/ext/srtp/libgstsrtp_la-gstsrtpenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/srtp/libgstsrtp_la-gstsrtp.lo
./gnome/gst-plugins-bad-1.8.2/ext/srtp/libgstsrtp_la-gstsrtp-enumtypes.lo
./gnome/gst-plugins-bad-1.8.2/ext/srtp/libgstsrtp_la-gstsrtpdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/bs2b/libgstbs2b_la-gstbs2b.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglcolorbalance.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglstereomix.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglcolorscale.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglsinkbin.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstgltestsrc.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglfilterglass.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglfiltercube.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglmosaic.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglstereosplit.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglbasemixer.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglfiltershader.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglimagesink.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstgluploadelement.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstgldeinterlace.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gltestsrc.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglmixerbin.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstgleffects.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglsrcbin.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglviewconvert.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstgloverlay.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglcolorconvertelement.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstgldifferencematte.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglmixer.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectmirror.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectscurves.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectsquare.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectsqueeze.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectsin.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectfisheye.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectlaplacian.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffecttwirl.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectssources.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectrgbtocurve.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectsobel.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffecttunnel.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectidentity.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectglow.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectbulge.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectstretch.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectblur.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectxray.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/effects/libgstopengl_la-gstgleffectlumatocurve.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstopengl.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglfilterapp.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglfilterbin.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstglvideomixer.lo
./gnome/gst-plugins-bad-1.8.2/ext/gl/libgstopengl_la-gstgldownloadelement.lo
./gnome/gst-plugins-bad-1.8.2/ext/ladspa/libgstladspa_la-gstladspautils.lo
./gnome/gst-plugins-bad-1.8.2/ext/ladspa/libgstladspa_la-gstladspafilter.lo
./gnome/gst-plugins-bad-1.8.2/ext/ladspa/libgstladspa_la-gstladspasource.lo
./gnome/gst-plugins-bad-1.8.2/ext/ladspa/libgstladspa_la-gstladspasink.lo
./gnome/gst-plugins-bad-1.8.2/ext/ladspa/libgstladspa_la-gstladspa.lo
./gnome/gst-plugins-bad-1.8.2/ext/mpeg2enc/libgstmpeg2enc_la-gstmpeg2encoptions.lo
./gnome/gst-plugins-bad-1.8.2/ext/mpeg2enc/libgstmpeg2enc_la-gstmpeg2encoder.lo
./gnome/gst-plugins-bad-1.8.2/ext/mpeg2enc/libgstmpeg2enc_la-gstmpeg2encpicturereader.lo
./gnome/gst-plugins-bad-1.8.2/ext/mpeg2enc/libgstmpeg2enc_la-gstmpeg2enc.lo
./gnome/gst-plugins-bad-1.8.2/ext/mpeg2enc/libgstmpeg2enc_la-gstmpeg2encstreamwriter.lo
./gnome/gst-plugins-bad-1.8.2/ext/soundtouch/libgstsoundtouch_la-gstbpmdetect.lo
./gnome/gst-plugins-bad-1.8.2/ext/soundtouch/libgstsoundtouch_la-gstpitch.lo
./gnome/gst-plugins-bad-1.8.2/ext/soundtouch/libgstsoundtouch_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/ext/openjpeg/libgstopenjpeg_la-gstopenjpegdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/openjpeg/libgstopenjpeg_la-gstopenjpeg.lo
./gnome/gst-plugins-bad-1.8.2/ext/openjpeg/libgstopenjpeg_la-gstopenjpegenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/rsvg/libgstrsvg_la-gstrsvgoverlay.lo
./gnome/gst-plugins-bad-1.8.2/ext/rsvg/libgstrsvg_la-gstrsvg.lo
./gnome/gst-plugins-bad-1.8.2/ext/rsvg/libgstrsvg_la-gstrsvgdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/gsm/libgstgsm_la-gstgsmdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/gsm/libgstgsm_la-gstgsm.lo
./gnome/gst-plugins-bad-1.8.2/ext/gsm/libgstgsm_la-gstgsmenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/gtk/libgstgtksink_la-gtkgstbasewidget.lo
./gnome/gst-plugins-bad-1.8.2/ext/gtk/libgstgtksink_la-gstgtkbasesink.lo
./gnome/gst-plugins-bad-1.8.2/ext/gtk/libgstgtksink_la-gstgtksink.lo
./gnome/gst-plugins-bad-1.8.2/ext/gtk/libgstgtksink_la-gtkgstwidget.lo
./gnome/gst-plugins-bad-1.8.2/ext/gtk/libgstgtksink_la-gtkgstglwidget.lo
./gnome/gst-plugins-bad-1.8.2/ext/gtk/libgstgtksink_la-gstplugin.lo
./gnome/gst-plugins-bad-1.8.2/ext/gtk/libgstgtksink_la-gstgtkglsink.lo
./gnome/gst-plugins-bad-1.8.2/ext/gtk/libgstgtksink_la-gstgtkutils.lo
./gnome/gst-plugins-bad-1.8.2/ext/directfb/libgstdfbvideosink_la-dfbvideosink.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-gstmpegdesc.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-resindvdbin.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-gstmpegdemux.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-rsnparsetter.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-rsninputselector.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-gstpesfilter.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-rsndec.lo
./gnome/gst-plugins-bad-1.8.2/ext/resindvd/libgstresindvd_la-resindvdsrc.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlsdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlssrtpbin.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlssrtpenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlsconnection.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlssrtpdec.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlsenc.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-plugin.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlssrtpdemux.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlscertificate.lo
./gnome/gst-plugins-bad-1.8.2/ext/dtls/libgstdtls_la-gstdtlsagent.lo
./gnome/gst-plugins-bad-1.8.2/ext/opus/libgstopusparse_la-gstopusparse.lo
./gnome/gst-plugins-bad-1.8.2/ext/opus/libgstopusparse_la-gstopusheader.lo
./gnome/gst-plugins-bad-1.8.2/ext/opus/libgstopusparse_la-gstopus.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-gstaudiovisualizer.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-install-plugins.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-missing-plugins.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-encoding-profile.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-descriptions.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-gstdiscoverer-types.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-codec-utils.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-pbutils-enumtypes.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-pbutils.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-encoding-target.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-gstdiscoverer.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/pbutils/libgstpbutils_1.0_la-gstpluginsbaseversion.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/app/libgstapp_1.0_la-gstappsink.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/app/libgstapp_1.0_la-gstappsrc.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/app/libgstapp_1.0_la-gstapp-marshal.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-colorbalance.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideoutils.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-converter.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-resampler.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-videooverlay.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideosink.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-scaler.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-format.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-overlay-composition.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-videoorientation.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-chroma.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideoutilsprivate.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-color.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideofilter.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideoencoder.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-blend.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideoaffinetransformationmeta.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-event.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-colorbalancechannel.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideodecoder.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-info.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-dither.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-convertframe.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideometa.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-gstvideopool.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-tmp-orc.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-frame.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-navigation.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-multiview.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-tile.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/video/libgstvideo_1.0_la-video-enumtypes.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/riff/libgstriff_1.0_la-riff.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/riff/libgstriff_1.0_la-riff-read.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/riff/libgstriff_1.0_la-riff-media.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudiodecoder.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudiosrc.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudiofilter.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudiobasesink.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-audio-quantize.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-audio-channels.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-audio-info.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-audio-converter.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudioutilsprivate.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudiocdsrc.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudioiec61937.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudiometa.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudioclock.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudiobasesrc.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-audio-channel-mixer.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-audio-format.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-audio.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudioringbuffer.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-audio-enumtypes.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-streamvolume.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudioencoder.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-tmp-orc.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/audio/libgstaudio_1.0_la-gstaudiosink.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/allocators/libgstallocators_1.0_la-gstdmabuf.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/allocators/libgstallocators_1.0_la-gstfdmemory.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtp/libgstrtp_1.0_la-gstrtp-enumtypes.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtp/libgstrtp_1.0_la-gstrtpbuffer.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtp/libgstrtp_1.0_la-gstrtppayloads.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtp/libgstrtp_1.0_la-gstrtpbasepayload.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtp/libgstrtp_1.0_la-gstrtpbaseaudiopayload.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtp/libgstrtp_1.0_la-gstrtpbasedepayload.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtp/libgstrtp_1.0_la-gstrtphdrext.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtp/libgstrtp_1.0_la-gstrtcpbuffer.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-tags.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-lang.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-gstid3tag.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-id3v2frames.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-id3v2.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-gsttagdemux.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-gstexiftag.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-gsttageditingprivate.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-gstvorbistag.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-gstxmptag.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-xmpwriter.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-gsttagmux.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/tag/libgsttag_1.0_la-licenses.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/sdp/libgstsdp_1.0_la-gstmikey.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/sdp/libgstsdp_1.0_la-gstsdpmessage.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-gstfftf32.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-kiss_fft_s32.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-kiss_fftr_s16.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-kiss_fftr_f32.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-kiss_fftr_f64.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-kiss_fft_f32.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-gstffts32.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-kiss_fftr_s32.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-gstfftf64.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-kiss_fft_f64.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-gstfft.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-gstffts16.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/fft/libgstfft_1.0_la-kiss_fft_s16.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtsp/libgstrtsp_1.0_la-gstrtspurl.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtsp/libgstrtsp_1.0_la-gstrtspdefs.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtsp/libgstrtsp_1.0_la-gstrtspconnection.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtsp/libgstrtsp_1.0_la-gstrtspextension.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtsp/libgstrtsp_1.0_la-gstrtsp-enumtypes.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtsp/libgstrtsp_1.0_la-gstrtspmessage.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtsp/libgstrtsp_1.0_la-gstrtsprange.lo
./gnome/gst-plugins-base-1.8.2/gst-libs/gst/rtsp/libgstrtsp_1.0_la-gstrtsptransport.lo
./gnome/gst-plugins-base-1.8.2/sys/ximage/libgstximagesink_la-ximage.lo
./gnome/gst-plugins-base-1.8.2/sys/ximage/libgstximagesink_la-ximagesink.lo
./gnome/gst-plugins-base-1.8.2/sys/ximage/libgstximagesink_la-ximagepool.lo
./gnome/gst-plugins-base-1.8.2/sys/xvimage/libgstxvimagesink_la-xvimagepool.lo
./gnome/gst-plugins-base-1.8.2/sys/xvimage/libgstxvimagesink_la-xvimageallocator.lo
./gnome/gst-plugins-base-1.8.2/sys/xvimage/libgstxvimagesink_la-xvimagesink.lo
./gnome/gst-plugins-base-1.8.2/sys/xvimage/libgstxvimagesink_la-xvcontext.lo
./gnome/gst-plugins-base-1.8.2/sys/xvimage/libgstxvimagesink_la-xvimage.lo
./gnome/gst-plugins-base-1.8.2/gst/videoscale/libgstvideoscale_la-gstvideoscale.lo
./gnome/gst-plugins-base-1.8.2/gst/app/libgstapp_la-gstapp.lo
./gnome/gst-plugins-base-1.8.2/gst/typefind/libgsttypefindfunctions_la-gsttypefindfunctions.lo
./gnome/gst-plugins-base-1.8.2/gst/videorate/libgstvideorate_la-gstvideorate.lo
./gnome/gst-plugins-base-1.8.2/gst/audioconvert/libgstaudioconvert_la-plugin.lo
./gnome/gst-plugins-base-1.8.2/gst/audioconvert/libgstaudioconvert_la-gstaudioconvert.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstplaybackutils.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstsubtitleoverlay.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstplaysinkaudioconvert.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstplay-enum.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstplaysink.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstplaybin2.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstplayback.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstplaysinkvideoconvert.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gsturidecodebin.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gststreamsynchronizer.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstplaysinkconvertbin.lo
./gnome/gst-plugins-base-1.8.2/gst/playback/libgstplayback_la-gstdecodebin2.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gstsocketsrc.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gsttcpclientsink.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gsttcpserversink.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gsttcpserversrc.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gsttcpclientsrc.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gsttcpplugin.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gstmultihandlesink.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gstmultifdsink.lo
./gnome/gst-plugins-base-1.8.2/gst/tcp/libgsttcp_la-gstmultisocketsink.lo
./gnome/gst-plugins-base-1.8.2/gst/videoconvert/libgstvideoconvert_la-gstvideoconvert.lo
./gnome/gst-plugins-base-1.8.2/gst/volume/libgstvolume_la-gstvolume.lo
./gnome/gst-plugins-base-1.8.2/gst/volume/libgstvolume_la-tmp-orc.lo
./gnome/gst-plugins-base-1.8.2/gst/encoding/libgstencodebin_la-gststreamcombiner.lo
./gnome/gst-plugins-base-1.8.2/gst/encoding/libgstencodebin_la-gstsmartencoder.lo
./gnome/gst-plugins-base-1.8.2/gst/encoding/libgstencodebin_la-gststreamsplitter.lo
./gnome/gst-plugins-base-1.8.2/gst/encoding/libgstencodebin_la-gstencodebin.lo
./gnome/gst-plugins-base-1.8.2/gst/subparse/libgstsubparse_la-qttextparse.lo
./gnome/gst-plugins-base-1.8.2/gst/subparse/libgstsubparse_la-samiparse.lo
./gnome/gst-plugins-base-1.8.2/gst/subparse/libgstsubparse_la-gstssaparse.lo
./gnome/gst-plugins-base-1.8.2/gst/subparse/libgstsubparse_la-tmplayerparse.lo
./gnome/gst-plugins-base-1.8.2/gst/subparse/libgstsubparse_la-mpl2parse.lo
./gnome/gst-plugins-base-1.8.2/gst/subparse/libgstsubparse_la-gstsubparse.lo
./gnome/gst-plugins-base-1.8.2/gst/audiotestsrc/libgstaudiotestsrc_la-gstaudiotestsrc.lo
./gnome/gst-plugins-base-1.8.2/gst/gio/libgstgio_la-gstgiostreamsrc.lo
./gnome/gst-plugins-base-1.8.2/gst/gio/libgstgio_la-gstgiosrc.lo
./gnome/gst-plugins-base-1.8.2/gst/gio/libgstgio_la-gstgiostreamsink.lo
./gnome/gst-plugins-base-1.8.2/gst/gio/libgstgio_la-gstgiosink.lo
./gnome/gst-plugins-base-1.8.2/gst/gio/libgstgio_la-gstgio.lo
./gnome/gst-plugins-base-1.8.2/gst/gio/libgstgio_la-gstgiobasesink.lo
./gnome/gst-plugins-base-1.8.2/gst/gio/libgstgio_la-gstgiobasesrc.lo
./gnome/gst-plugins-base-1.8.2/gst/audioresample/libgstaudioresample_la-speex_resampler_int.lo
./gnome/gst-plugins-base-1.8.2/gst/audioresample/libgstaudioresample_la-gstaudioresample.lo
./gnome/gst-plugins-base-1.8.2/gst/audioresample/libgstaudioresample_la-speex_resampler_double.lo
./gnome/gst-plugins-base-1.8.2/gst/audioresample/libgstaudioresample_la-speex_resampler_float.lo
./gnome/gst-plugins-base-1.8.2/gst/audiorate/libgstaudiorate_la-gstaudiorate.lo
./gnome/gst-plugins-base-1.8.2/gst/adder/libgstadder_la-tmp-orc.lo
./gnome/gst-plugins-base-1.8.2/gst/adder/libgstadder_la-gstadder.lo
./gnome/gst-plugins-base-1.8.2/gst/videotestsrc/libgstvideotestsrc_la-tmp-orc.lo
./gnome/gst-plugins-base-1.8.2/gst/videotestsrc/libgstvideotestsrc_la-videotestsrc.lo
./gnome/gst-plugins-base-1.8.2/gst/videotestsrc/libgstvideotestsrc_la-gstvideotestsrc.lo
./gnome/gst-plugins-base-1.8.2/ext/cdparanoia/libgstcdparanoia_la-gstcdparanoiasrc.lo
./gnome/gst-plugins-base-1.8.2/ext/vorbis/libgstvorbis_la-gstvorbiscommon.lo
./gnome/gst-plugins-base-1.8.2/ext/vorbis/libgstvorbis_la-gstvorbisdeclib.lo
./gnome/gst-plugins-base-1.8.2/ext/vorbis/libgstvorbis_la-gstvorbisdec.lo
./gnome/gst-plugins-base-1.8.2/ext/vorbis/libgstvorbis_la-gstvorbisenc.lo
./gnome/gst-plugins-base-1.8.2/ext/vorbis/libgstvorbis_la-gstvorbistag.lo
./gnome/gst-plugins-base-1.8.2/ext/vorbis/libgstvorbis_la-gstvorbisparse.lo
./gnome/gst-plugins-base-1.8.2/ext/vorbis/libgstvorbis_la-gstvorbis.lo
./gnome/gst-plugins-base-1.8.2/ext/alsa/libgstalsa_la-gstalsasrc.lo
./gnome/gst-plugins-base-1.8.2/ext/alsa/libgstalsa_la-gstalsamidisrc.lo
./gnome/gst-plugins-base-1.8.2/ext/alsa/libgstalsa_la-gstalsaplugin.lo
./gnome/gst-plugins-base-1.8.2/ext/alsa/libgstalsa_la-gstalsadeviceprobe.lo
./gnome/gst-plugins-base-1.8.2/ext/alsa/libgstalsa_la-gstalsa.lo
./gnome/gst-plugins-base-1.8.2/ext/alsa/libgstalsa_la-gstalsasink.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-gstoggmux.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-gstoggdemux.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-gstogg.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-dirac_parse.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-gstoggparse.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-gstogmparse.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-vorbis_parse.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-gstoggaviparse.lo
./gnome/gst-plugins-base-1.8.2/ext/ogg/libgstogg_la-gstoggstream.lo
./gnome/gst-plugins-base-1.8.2/ext/theora/libgsttheora_la-gsttheora.lo
./gnome/gst-plugins-base-1.8.2/ext/theora/libgsttheora_la-gsttheoraparse.lo
./gnome/gst-plugins-base-1.8.2/ext/theora/libgsttheora_la-gsttheoradec.lo
./gnome/gst-plugins-base-1.8.2/ext/theora/libgsttheora_la-gsttheoraenc.lo
./gnome/gst-plugins-base-1.8.2/ext/pango/libgstpango_la-gsttextrender.lo
./gnome/gst-plugins-base-1.8.2/ext/pango/libgstpango_la-gsttimeoverlay.lo
./gnome/gst-plugins-base-1.8.2/ext/pango/libgstpango_la-gsttextoverlay.lo
./gnome/gst-plugins-base-1.8.2/ext/pango/libgstpango_la-gstbasetextoverlay.lo
./gnome/gst-plugins-base-1.8.2/ext/pango/libgstpango_la-gstclockoverlay.lo
./gnome/gst-plugins-base-1.8.2/ext/libvisual/libgstlibvisual_la-plugin.lo
./gnome/gst-plugins-base-1.8.2/ext/libvisual/libgstlibvisual_la-visual.lo
./gnome/gst-plugins-base-1.8.2/ext/opus/libgstopus_la-gstopusenc.lo
./gnome/gst-plugins-base-1.8.2/ext/opus/libgstopus_la-gstopusheader.lo
./gnome/gst-plugins-base-1.8.2/ext/opus/libgstopus_la-gstopus.lo
./gnome/gst-plugins-base-1.8.2/ext/opus/libgstopus_la-gstopusdec.lo
./gnome/gst-plugins-base-1.8.2/ext/opus/libgstopus_la-gstopuscommon.lo
./gnome/gst-plugins-ugly-1.8.2/gst/dvdlpcmdec/libgstdvdlpcmdec_la-gstdvdlpcmdec.lo
./gnome/gst-plugins-ugly-1.8.2/gst/asfdemux/libgstasf_la-gstasfdemux.lo
./gnome/gst-plugins-ugly-1.8.2/gst/asfdemux/libgstasf_la-gstrtpasfdepay.lo
./gnome/gst-plugins-ugly-1.8.2/gst/asfdemux/libgstasf_la-gstasf.lo
./gnome/gst-plugins-ugly-1.8.2/gst/asfdemux/libgstasf_la-asfpacket.lo
./gnome/gst-plugins-ugly-1.8.2/gst/asfdemux/libgstasf_la-gstrtspwms.lo
./gnome/gst-plugins-ugly-1.8.2/gst/asfdemux/libgstasf_la-asfheaders.lo
./gnome/gst-plugins-ugly-1.8.2/gst/xingmux/libgstxingmux_la-gstxingmux.lo
./gnome/gst-plugins-ugly-1.8.2/gst/xingmux/libgstxingmux_la-plugin.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-realmedia.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-asmrules.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-rdtmanager.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-rmutils.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-rademux.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-rtspreal.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-rdtjitterbuffer.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-rmdemux.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-rdtdepay.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-gstrdtbuffer.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-pnmsrc.lo
./gnome/gst-plugins-ugly-1.8.2/gst/realmedia/libgstrmdemux_la-realhash.lo
./gnome/gst-plugins-ugly-1.8.2/gst/dvdsub/libgstdvdsub_la-gstdvdsubparse.lo
./gnome/gst-plugins-ugly-1.8.2/gst/dvdsub/libgstdvdsub_la-gstdvdsubdec.lo
./gnome/gst-plugins-ugly-1.8.2/ext/dvdread/libgstdvdread_la-dvdreadsrc.lo
./gnome/gst-plugins-ugly-1.8.2/ext/mpeg2dec/libgstmpeg2dec_la-gstmpeg2dec.lo
./gnome/gst-plugins-ugly-1.8.2/ext/sidplay/libgstsid_la-gstsiddec.lo
./gnome/gst-plugins-ugly-1.8.2/ext/amrnb/libgstamrnb_la-amrnb.lo
./gnome/gst-plugins-ugly-1.8.2/ext/amrnb/libgstamrnb_la-amrnbdec.lo
./gnome/gst-plugins-ugly-1.8.2/ext/amrnb/libgstamrnb_la-amrnbenc.lo
./gnome/gst-plugins-ugly-1.8.2/ext/mpg123/libgstmpg123_la-gstmpg123audiodec.lo
./gnome/gst-plugins-ugly-1.8.2/ext/cdio/libgstcdio_la-gstcdio.lo
./gnome/gst-plugins-ugly-1.8.2/ext/cdio/libgstcdio_la-gstcdiocddasrc.lo
./gnome/gst-plugins-ugly-1.8.2/ext/a52dec/libgsta52dec_la-gsta52dec.lo
./gnome/gst-plugins-ugly-1.8.2/ext/mad/libgstmad_la-gstmad.lo
./gnome/gst-plugins-ugly-1.8.2/ext/x264/libgstx264_la-gstx264enc.lo
./gnome/gst-plugins-ugly-1.8.2/ext/amrwbdec/libgstamrwbdec_la-amrwbdec.lo
./gnome/gst-plugins-ugly-1.8.2/ext/amrwbdec/libgstamrwbdec_la-amrwb.lo
./gnome/gst-plugins-ugly-1.8.2/ext/twolame/libgsttwolame_la-gsttwolamemp2enc.lo
./gnome/gst-plugins-ugly-1.8.2/ext/lame/libgstlame_la-plugin.lo
./gnome/gst-plugins-ugly-1.8.2/ext/lame/libgstlame_la-gstlamemp3enc.lo
./gnome/gst-plugins-espeak-0.4.0/src/libgstespeak_la-gstespeak.lo
./gnome/gst-plugins-espeak-0.4.0/src/libgstespeak_la-espeak.lo
./gnome/pocketsphinx/swig/python/pocketsphinx_wrap.lo
./gnome/pocketsphinx/src/gst-plugin/gstpocketsphinx.lo
./gnome/pocketsphinx/src/libpocketsphinx/vector.lo
./gnome/pocketsphinx/src/libpocketsphinx/blkarray_list.lo
./gnome/pocketsphinx/src/libpocketsphinx/phone_loop_search.lo
./gnome/pocketsphinx/src/libpocketsphinx/ps_lattice.lo
./gnome/pocketsphinx/src/libpocketsphinx/state_align_search.lo
./gnome/pocketsphinx/src/libpocketsphinx/fsg_search.lo
./gnome/pocketsphinx/src/libpocketsphinx/mdef.lo
./gnome/pocketsphinx/src/libpocketsphinx/allphone_search.lo
./gnome/pocketsphinx/src/libpocketsphinx/ps_alignment.lo
./gnome/pocketsphinx/src/libpocketsphinx/dict2pid.lo
./gnome/pocketsphinx/src/libpocketsphinx/ms_gauden.lo
./gnome/pocketsphinx/src/libpocketsphinx/hmm.lo
./gnome/pocketsphinx/src/libpocketsphinx/kws_detections.lo
./gnome/pocketsphinx/src/libpocketsphinx/fsg_history.lo
./gnome/pocketsphinx/src/libpocketsphinx/ms_mgau.lo
./gnome/pocketsphinx/src/libpocketsphinx/pocketsphinx.lo
./gnome/pocketsphinx/src/libpocketsphinx/ptm_mgau.lo
./gnome/pocketsphinx/src/libpocketsphinx/kws_search.lo
./gnome/pocketsphinx/src/libpocketsphinx/tmat.lo
./gnome/pocketsphinx/src/libpocketsphinx/s2_semi_mgau.lo
./gnome/pocketsphinx/src/libpocketsphinx/ngram_search.lo
./gnome/pocketsphinx/src/libpocketsphinx/ngram_search_fwdtree.lo
./gnome/pocketsphinx/src/libpocketsphinx/ps_mllr.lo
./gnome/pocketsphinx/src/libpocketsphinx/acmod.lo
./gnome/pocketsphinx/src/libpocketsphinx/dict.lo
./gnome/pocketsphinx/src/libpocketsphinx/ms_senone.lo
./gnome/pocketsphinx/src/libpocketsphinx/bin_mdef.lo
./gnome/pocketsphinx/src/libpocketsphinx/ngram_search_fwdflat.lo
./gnome/pocketsphinx/src/libpocketsphinx/fsg_lextree.lo
./gnome/gst-plugins-good-1.8.2/sys/ximage/libgstximagesrc_la-gstximagesrc.lo
./gnome/gst-plugins-good-1.8.2/sys/ximage/libgstximagesrc_la-ximageutil.lo
./gnome/gst-plugins-good-1.8.2/sys/oss/libgstossaudio_la-gstosssink.lo
./gnome/gst-plugins-good-1.8.2/sys/oss/libgstossaudio_la-gstosshelper.lo
./gnome/gst-plugins-good-1.8.2/sys/oss/libgstossaudio_la-gstossaudio.lo
./gnome/gst-plugins-good-1.8.2/sys/oss/libgstossaudio_la-gstosssrc.lo
./gnome/gst-plugins-good-1.8.2/sys/oss4/libgstoss4audio_la-oss4-sink.lo
./gnome/gst-plugins-good-1.8.2/sys/oss4/libgstoss4audio_la-oss4-source.lo
./gnome/gst-plugins-good-1.8.2/sys/oss4/libgstoss4audio_la-oss4-property-probe.lo
./gnome/gst-plugins-good-1.8.2/sys/oss4/libgstoss4audio_la-oss4-audio.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2videodec.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2vidorient.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2colorbalance.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2tuner.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-v4l2-utils.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-v4l2_calls.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2bufferpool.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-tunernorm.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-tunerchannel.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2src.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2radio.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2sink.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2deviceprovider.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2allocator.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2object.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-tuner.lo
./gnome/gst-plugins-good-1.8.2/sys/v4l2/libgstvideo4linux2_la-gstv4l2transform.lo
./gnome/gst-plugins-good-1.8.2/tests/check/elements/libparser_la-parser.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiowsincband.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiocheblimit.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiofxbasefirfilter.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audioamplify.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audioecho.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiofirfilter.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audioinvert.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audioiirfilter.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-gstscaletempo.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiofx.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiokaraoke.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiofxbaseiirfilter.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiopanorama.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiochebband.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiodynamic.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-tmp-orc.lo
./gnome/gst-plugins-good-1.8.2/gst/audiofx/libgstaudiofx_la-audiowsinclimit.lo
./gnome/gst-plugins-good-1.8.2/gst/videobox/libgstvideobox_la-tmp-orc.lo
./gnome/gst-plugins-good-1.8.2/gst/videobox/libgstvideobox_la-gstvideobox.lo
./gnome/gst-plugins-good-1.8.2/gst/id3demux/libgstid3demux_la-gstid3demux.lo
./gnome/gst-plugins-good-1.8.2/gst/spectrum/libgstspectrum_la-gstspectrum.lo
./gnome/gst-plugins-good-1.8.2/gst/wavparse/libgstwavparse_la-gstwavparse.lo
./gnome/gst-plugins-good-1.8.2/gst/flx/libgstflxdec_la-flx_color.lo
./gnome/gst-plugins-good-1.8.2/gst/flx/libgstflxdec_la-gstflxdec.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-gstamrparse.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-gstmpegaudioparse.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-plugin.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-gstsbcparse.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-gstdcaparse.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-gstflacparse.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-gstwavpackparse.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-gstac3parse.lo
./gnome/gst-plugins-good-1.8.2/gst/audioparsers/libgstaudioparsers_la-gstaacparse.lo
./gnome/gst-plugins-good-1.8.2/gst/avi/libgstavi_la-gstavi.lo
./gnome/gst-plugins-good-1.8.2/gst/avi/libgstavi_la-gstavimux.lo
./gnome/gst-plugins-good-1.8.2/gst/avi/libgstavi_la-gstavidemux.lo
./gnome/gst-plugins-good-1.8.2/gst/avi/libgstavi_la-gstavisubtitle.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstdice.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstaging.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstshagadelic.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstedge.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstvertigo.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstradioac.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstwarp.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstquark.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstripple.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gsteffectv.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gststreak.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstop.lo
./gnome/gst-plugins-good-1.8.2/gst/effectv/libgsteffectv_la-gstrev.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-mathtools.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-sound_tester.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-ifs.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-gstgoom.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-config_param.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-surf3d.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-plugin_info.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-goom_tools.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-filters.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-goom_core.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-flying_stars_fx.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-v3d.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-lines.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-convolve_fx.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-drawmethods.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-tentacle3d.lo
./gnome/gst-plugins-good-1.8.2/gst/goom/libgstgoom_la-graphic.lo
./gnome/gst-plugins-good-1.8.2/gst/apetag/libgstapetag_la-gstapedemux.lo
./gnome/gst-plugins-good-1.8.2/gst/replaygain/libgstreplaygain_la-gstrglimiter.lo
./gnome/gst-plugins-good-1.8.2/gst/replaygain/libgstreplaygain_la-replaygain.lo
./gnome/gst-plugins-good-1.8.2/gst/replaygain/libgstreplaygain_la-gstrgvolume.lo
./gnome/gst-plugins-good-1.8.2/gst/replaygain/libgstreplaygain_la-gstrganalysis.lo
./gnome/gst-plugins-good-1.8.2/gst/replaygain/libgstreplaygain_la-rganalysis.lo
./gnome/gst-plugins-good-1.8.2/gst/auparse/libgstauparse_la-gstauparse.lo
./gnome/gst-plugins-good-1.8.2/gst/goom2k1/libgstgoom2k1_la-lines.lo
./gnome/gst-plugins-good-1.8.2/gst/goom2k1/libgstgoom2k1_la-gstgoom.lo
./gnome/gst-plugins-good-1.8.2/gst/goom2k1/libgstgoom2k1_la-filters.lo
./gnome/gst-plugins-good-1.8.2/gst/goom2k1/libgstgoom2k1_la-graphic.lo
./gnome/gst-plugins-good-1.8.2/gst/goom2k1/libgstgoom2k1_la-goom_core.lo
./gnome/gst-plugins-good-1.8.2/gst/smpte/libgstsmpte_la-gstsmpte.lo
./gnome/gst-plugins-good-1.8.2/gst/smpte/libgstsmpte_la-gstmask.lo
./gnome/gst-plugins-good-1.8.2/gst/smpte/libgstsmpte_la-gstsmptealpha.lo
./gnome/gst-plugins-good-1.8.2/gst/smpte/libgstsmpte_la-plugin.lo
./gnome/gst-plugins-good-1.8.2/gst/smpte/libgstsmpte_la-barboxwipes.lo
./gnome/gst-plugins-good-1.8.2/gst/smpte/libgstsmpte_la-paint.lo
./gnome/gst-plugins-good-1.8.2/gst/flv/libgstflv_la-gstflvmux.lo
./gnome/gst-plugins-good-1.8.2/gst/flv/libgstflv_la-gstflvdemux.lo
./gnome/gst-plugins-good-1.8.2/gst/icydemux/libgsticydemux_la-gsticydemux.lo
./gnome/gst-plugins-good-1.8.2/gst/imagefreeze/libgstimagefreeze_la-gstimagefreeze.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/libgstdeinterlace_la-gstdeinterlacemethod.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-greedy.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-scalerbob.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-vfir.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-weave.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-linearblend.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-greedyh.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-weavetff.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-linear.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-weavebff.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/tvtime/libgstdeinterlace_la-tomsmocomp.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/libgstdeinterlace_la-gstdeinterlace.lo
./gnome/gst-plugins-good-1.8.2/gst/deinterlace/libgstdeinterlace_la-tmp-orc.lo
./gnome/gst-plugins-good-1.8.2/gst/cutter/libgstcutter_la-gstcutter.lo
./gnome/gst-plugins-good-1.8.2/gst/autodetect/libgstautodetect_la-gstautoaudiosrc.lo
./gnome/gst-plugins-good-1.8.2/gst/autodetect/libgstautodetect_la-gstautovideosrc.lo
./gnome/gst-plugins-good-1.8.2/gst/autodetect/libgstautodetect_la-gstautovideosink.lo
./gnome/gst-plugins-good-1.8.2/gst/autodetect/libgstautodetect_la-gstautoaudiosink.lo
./gnome/gst-plugins-good-1.8.2/gst/autodetect/libgstautodetect_la-gstautodetect.lo
./gnome/gst-plugins-good-1.8.2/gst/shapewipe/libgstshapewipe_la-gstshapewipe.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-tests.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-testplugin.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-gstcapssetter.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstnavigationtest_la-gstnavigationtest.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-gsttaginject.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-cpureport.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-rndbuffersize.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-gstnavseek.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-progressreport.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-breakmydata.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-gstdebug.lo
./gnome/gst-plugins-good-1.8.2/gst/debugutils/libgstdebug_la-gstpushfilesrc.lo
./gnome/gst-plugins-good-1.8.2/gst/interleave/libgstinterleave_la-plugin.lo
./gnome/gst-plugins-good-1.8.2/gst/interleave/libgstinterleave_la-interleave.lo
./gnome/gst-plugins-good-1.8.2/gst/interleave/libgstinterleave_la-deinterleave.lo
./gnome/gst-plugins-good-1.8.2/gst/videofilter/libgstvideofilter_la-plugin.lo
./gnome/gst-plugins-good-1.8.2/gst/videofilter/libgstvideofilter_la-gstvideobalance.lo
./gnome/gst-plugins-good-1.8.2/gst/videofilter/libgstvideofilter_la-gstvideoflip.lo
./gnome/gst-plugins-good-1.8.2/gst/videofilter/libgstvideofilter_la-gstvideomedian.lo
./gnome/gst-plugins-good-1.8.2/gst/videofilter/libgstvideofilter_la-gstgamma.lo
./gnome/gst-plugins-good-1.8.2/gst/videomixer/libgstvideomixer_la-tmp-orc.lo
./gnome/gst-plugins-good-1.8.2/gst/videomixer/libgstvideomixer_la-videomixer2.lo
./gnome/gst-plugins-good-1.8.2/gst/videomixer/libgstvideomixer_la-blend.lo
./gnome/gst-plugins-good-1.8.2/gst/equalizer/libgstequalizer_la-gstiirequalizer.lo
./gnome/gst-plugins-good-1.8.2/gst/equalizer/libgstequalizer_la-gstiirequalizernbands.lo
./gnome/gst-plugins-good-1.8.2/gst/equalizer/libgstequalizer_la-gstiirequalizer3bands.lo
./gnome/gst-plugins-good-1.8.2/gst/equalizer/libgstequalizer_la-gstiirequalizer10bands.lo
./gnome/gst-plugins-good-1.8.2/gst/wavenc/libgstwavenc_la-gstwavenc.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-matroska-mux.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-ebml-write.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-matroska-read-common.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-matroska.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-matroska-demux.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-webm-mux.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-matroska-ids.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-lzo.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-ebml-read.lo
./gnome/gst-plugins-good-1.8.2/gst/matroska/libgstmatroska_la-matroska-parse.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph265depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpceltpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpac3depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpL24depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp2tpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpgstpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpsirenpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpqcelpdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph264depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpg726depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpspeexdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph263ppay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpgstdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtputils.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpstreampay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpvrawdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph263pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpchannels.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpvp8depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmparobustdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpbvpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpg729pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph261pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmpadepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpopuspay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp4gdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpj2kpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpdvdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpg723pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpspeexpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmpvpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpgsmdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpjpegpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtppcmudepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpgsmpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpL16pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpvp9depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpklvdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmpapay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpamrpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpj2kdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtptheoradepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-dboolhuff.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpvp9pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp4apay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpklvpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpstreamdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph263depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpvp8pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtppcmapay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpg722depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpsbcpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpg722pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtppcmadepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpopusdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpL16depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpg726pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpg729depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpvorbisdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph265pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp4vdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpbvdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpac3pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp4gpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtptheorapay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpL24pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpilbcdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp4adepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp4vpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtp.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpamrdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpilbcpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-fnv1hash.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpjpegdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph261depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpsirendepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph264pay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpsbcdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpdvpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpvrawpay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmpvdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpvorbispay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpsv3vdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpg723depay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtppcmupay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpqdmdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpceltdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp1sdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtpmp2tdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstrtph263pdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/rtp/libgstrtp_la-gstasteriskh263.lo
./gnome/gst-plugins-good-1.8.2/gst/law/libgstalaw_la-alaw-encode.lo
./gnome/gst-plugins-good-1.8.2/gst/law/libgstalaw_la-alaw-decode.lo
./gnome/gst-plugins-good-1.8.2/gst/law/libgstmulaw_la-mulaw.lo
./gnome/gst-plugins-good-1.8.2/gst/law/libgstmulaw_la-mulaw-encode.lo
./gnome/gst-plugins-good-1.8.2/gst/law/libgstalaw_la-alaw.lo
./gnome/gst-plugins-good-1.8.2/gst/law/libgstmulaw_la-mulaw-decode.lo
./gnome/gst-plugins-good-1.8.2/gst/law/libgstmulaw_la-mulaw-conversion.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-gstmultifilesink.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-gstsplitfilesrc.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-gstsplitmuxsrc.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-gstsplitutils.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-patternspec.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-gstsplitmuxpartreader.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-gstsplitmuxsink.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-gstmultifile.lo
./gnome/gst-plugins-good-1.8.2/gst/multifile/libgstmultifile_la-gstmultifilesrc.lo
./gnome/gst-plugins-good-1.8.2/gst/y4m/libgsty4menc_la-gsty4mencode.lo
./gnome/gst-plugins-good-1.8.2/gst/alpha/libgstalpha_la-gstalpha.lo
./gnome/gst-plugins-good-1.8.2/gst/alpha/libgstalphacolor_la-gstalphacolor.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtprtxsend.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtpjitterbuffer.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtpbin.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtpmux.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtpssrcdemux.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtpptdemux.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtprtxreceive.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-rtpjitterbuffer.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-rtpsession.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtpsession.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-rtpstats.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtpdtmfmux.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtpmanager.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-rtpsource.lo
./gnome/gst-plugins-good-1.8.2/gst/rtpmanager/libgstrtpmanager_la-gstrtprtxqueue.lo
./gnome/gst-plugins-good-1.8.2/gst/videocrop/libgstvideocrop_la-gstaspectratiocrop.lo
./gnome/gst-plugins-good-1.8.2/gst/videocrop/libgstvideocrop_la-gstvideocrop.lo
./gnome/gst-plugins-good-1.8.2/gst/rtsp/libgstrtsp_la-gstrtpdec.lo
./gnome/gst-plugins-good-1.8.2/gst/rtsp/libgstrtsp_la-gstrtspext.lo
./gnome/gst-plugins-good-1.8.2/gst/rtsp/libgstrtsp_la-gstrtspsrc.lo
./gnome/gst-plugins-good-1.8.2/gst/rtsp/libgstrtsp_la-gstrtsp.lo
./gnome/gst-plugins-good-1.8.2/gst/udp/libgstudp_la-gstudpsrc.lo
./gnome/gst-plugins-good-1.8.2/gst/udp/libgstudp_la-gstdynudpsink.lo
./gnome/gst-plugins-good-1.8.2/gst/udp/libgstudp_la-gstudp.lo
./gnome/gst-plugins-good-1.8.2/gst/udp/libgstudp_la-gstmultiudpsink.lo
./gnome/gst-plugins-good-1.8.2/gst/udp/libgstudp_la-gstudpsink.lo
./gnome/gst-plugins-good-1.8.2/gst/udp/libgstudp_la-gstudpnetutils.lo
./gnome/gst-plugins-good-1.8.2/gst/dtmf/libgstdtmf_la-gstdtmfsrc.lo
./gnome/gst-plugins-good-1.8.2/gst/dtmf/libgstdtmf_la-gstrtpdtmfdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/dtmf/libgstdtmf_la-gstrtpdtmfsrc.lo
./gnome/gst-plugins-good-1.8.2/gst/dtmf/libgstdtmf_la-gstdtmf.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-gstrtpxqtdepay.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-qtdemux.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-isomp4-plugin.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-atoms.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-qtdemux_lang.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-descriptors.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-properties.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-qtdemux_types.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-atomsrecovery.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-gstqtmuxmap.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-gstqtmux.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-gstisoff.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-gstqtmoovrecover.lo
./gnome/gst-plugins-good-1.8.2/gst/isomp4/libgstisomp4_la-qtdemux_dump.lo
./gnome/gst-plugins-good-1.8.2/gst/multipart/libgstmultipart_la-multipartmux.lo
./gnome/gst-plugins-good-1.8.2/gst/multipart/libgstmultipart_la-multipartdemux.lo
./gnome/gst-plugins-good-1.8.2/gst/multipart/libgstmultipart_la-multipart.lo
./gnome/gst-plugins-good-1.8.2/gst/level/libgstlevel_la-gstlevel.lo
./gnome/gst-plugins-good-1.8.2/ext/vpx/libgstvpx_la-gstvp8dec.lo
./gnome/gst-plugins-good-1.8.2/ext/vpx/libgstvpx_la-gstvpxdec.lo
./gnome/gst-plugins-good-1.8.2/ext/vpx/libgstvpx_la-gstvp9dec.lo
./gnome/gst-plugins-good-1.8.2/ext/vpx/libgstvpx_la-gstvp8enc.lo
./gnome/gst-plugins-good-1.8.2/ext/vpx/libgstvpx_la-plugin.lo
./gnome/gst-plugins-good-1.8.2/ext/vpx/libgstvpx_la-gstvp9enc.lo
./gnome/gst-plugins-good-1.8.2/ext/vpx/libgstvpx_la-gstvp8utils.lo
./gnome/gst-plugins-good-1.8.2/ext/vpx/libgstvpx_la-gstvpxenc.lo
./gnome/gst-plugins-good-1.8.2/ext/wavpack/libgstwavpack_la-gstwavpackstreamreader.lo
./gnome/gst-plugins-good-1.8.2/ext/wavpack/libgstwavpack_la-gstwavpack.lo
./gnome/gst-plugins-good-1.8.2/ext/wavpack/libgstwavpack_la-gstwavpackdec.lo
./gnome/gst-plugins-good-1.8.2/ext/wavpack/libgstwavpack_la-gstwavpackenc.lo
./gnome/gst-plugins-good-1.8.2/ext/wavpack/libgstwavpack_la-gstwavpackcommon.lo
./gnome/gst-plugins-good-1.8.2/ext/dv/libgstdv_la-gstdvdec.lo
./gnome/gst-plugins-good-1.8.2/ext/dv/libgstdv_la-gstdvdemux.lo
./gnome/gst-plugins-good-1.8.2/ext/dv/libgstdv_la-gstsmptetimecode.lo
./gnome/gst-plugins-good-1.8.2/ext/dv/libgstdv_la-gstdv.lo
./gnome/gst-plugins-good-1.8.2/ext/jpeg/libgstjpeg_la-gstjpeg.lo
./gnome/gst-plugins-good-1.8.2/ext/jpeg/libgstjpeg_la-gstjpegdec.lo
./gnome/gst-plugins-good-1.8.2/ext/jpeg/libgstjpeg_la-gstjpegenc.lo
./gnome/gst-plugins-good-1.8.2/ext/taglib/libgsttaglib_la-gstapev2mux.lo
./gnome/gst-plugins-good-1.8.2/ext/taglib/libgsttaglib_la-gstid3v2mux.lo
./gnome/gst-plugins-good-1.8.2/ext/taglib/libgsttaglib_la-gsttaglibplugin.lo
./gnome/gst-plugins-good-1.8.2/ext/flac/libgstflac_la-gstflac.lo
./gnome/gst-plugins-good-1.8.2/ext/flac/libgstflac_la-gstflacdec.lo
./gnome/gst-plugins-good-1.8.2/ext/flac/libgstflac_la-gstflactag.lo
./gnome/gst-plugins-good-1.8.2/ext/flac/libgstflac_la-gstflacenc.lo
./gnome/gst-plugins-good-1.8.2/ext/libcaca/libgstcacasink_la-gstcacasink.lo
./gnome/gst-plugins-good-1.8.2/ext/raw1394/libgst1394_la-gst1394clock.lo
./gnome/gst-plugins-good-1.8.2/ext/raw1394/libgst1394_la-gst1394.lo
./gnome/gst-plugins-good-1.8.2/ext/raw1394/libgst1394_la-gstdv1394src.lo
./gnome/gst-plugins-good-1.8.2/ext/raw1394/libgst1394_la-gsthdv1394src.lo
./gnome/gst-plugins-good-1.8.2/ext/raw1394/libgst1394_la-gst1394probe.lo
./gnome/gst-plugins-good-1.8.2/ext/soup/libgstsouphttpsrc_la-gstsouputils.lo
./gnome/gst-plugins-good-1.8.2/ext/soup/libgstsouphttpsrc_la-gstsouphttpclientsink.lo
./gnome/gst-plugins-good-1.8.2/ext/soup/libgstsouphttpsrc_la-gstsouphttpsrc.lo
./gnome/gst-plugins-good-1.8.2/ext/soup/libgstsouphttpsrc_la-gstsoup.lo
./gnome/gst-plugins-good-1.8.2/ext/pulse/libgstpulse_la-pulsesink.lo
./gnome/gst-plugins-good-1.8.2/ext/pulse/libgstpulse_la-pulsesrc.lo
./gnome/gst-plugins-good-1.8.2/ext/pulse/libgstpulse_la-pulseutil.lo
./gnome/gst-plugins-good-1.8.2/ext/pulse/libgstpulse_la-pulsedeviceprovider.lo
./gnome/gst-plugins-good-1.8.2/ext/pulse/libgstpulse_la-plugin.lo
./gnome/gst-plugins-good-1.8.2/ext/shout2/libgstshout2_la-gstshout2.lo
./gnome/gst-plugins-good-1.8.2/ext/cairo/libgstcairo_la-gstcairo.lo
./gnome/gst-plugins-good-1.8.2/ext/cairo/libgstcairo_la-gstcairooverlay.lo
./gnome/gst-plugins-good-1.8.2/ext/aalib/libgstaasink_la-gstaasink.lo
./gnome/gst-plugins-good-1.8.2/ext/jack/libgstjack_la-gstjackaudioclient.lo
./gnome/gst-plugins-good-1.8.2/ext/jack/libgstjack_la-gstjackutil.lo
./gnome/gst-plugins-good-1.8.2/ext/jack/libgstjack_la-gstjackaudiosink.lo
./gnome/gst-plugins-good-1.8.2/ext/jack/libgstjack_la-gstjackaudiosrc.lo
./gnome/gst-plugins-good-1.8.2/ext/jack/libgstjack_la-gstjack.lo
./gnome/gst-plugins-good-1.8.2/ext/gdk_pixbuf/libgstgdkpixbuf_la-gstgdkpixbufplugin.lo
./gnome/gst-plugins-good-1.8.2/ext/gdk_pixbuf/libgstgdkpixbuf_la-gstgdkpixbufdec.lo
./gnome/gst-plugins-good-1.8.2/ext/gdk_pixbuf/libgstgdkpixbuf_la-gstgdkpixbufoverlay.lo
./gnome/gst-plugins-good-1.8.2/ext/gdk_pixbuf/libgstgdkpixbuf_la-gstgdkpixbufsink.lo
./gnome/gst-plugins-good-1.8.2/ext/speex/libgstspeex_la-gstspeexenc.lo
./gnome/gst-plugins-good-1.8.2/ext/speex/libgstspeex_la-gstspeexdec.lo
./gnome/gst-plugins-good-1.8.2/ext/speex/libgstspeex_la-gstspeex.lo
./gnome/gst-plugins-good-1.8.2/ext/libpng/libgstpng_la-gstpngenc.lo
./gnome/gst-plugins-good-1.8.2/ext/libpng/libgstpng_la-gstpng.lo
./gnome/gst-plugins-good-1.8.2/ext/libpng/libgstpng_la-gstpngdec.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavdemux.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavutils.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavauddec.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstav.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavcfg.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavprotocol.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavvidenc.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavdeinterlace.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavaudenc.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavviddec.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavcodecmap.lo
./gnome/gst-libav-1.8.2/ext/libav/libgstlibav_la-gstavmux.lo
[pi@414f388874c0 ~] $


# finally, lets add these to goss

for i in $(find ./gnome -maxdepth 1 -type d -print | grep -v "^./gnome$" | xargs); do
  # then do a find in that folder for all .lo files created in the past day
  for j in $(find $i -name "*.lo" -mtime -2 -print | xargs); do
    goss a file $j; done
  done
done
```


### bash script to generate command.echo $PATH tests ( etc )

*cat tests:*

```
# This one creates the cat /var/run/s6/container_environment/{VAR_NAME} tests
# Create goss test file
touch /home/pi/bash_generated_goss.yaml
cat <<EOF > /home/pi/bash_generated_goss.yaml
command:
EOF

# validate it looks good visually
cat /home/pi/bash_generated_goss.yaml

# Begin segment to generate it dynamically
CONTAINER_ENV_LOC=/var/run/s6/container_environment/*

# env var check
for f in $CONTAINER_ENV_LOC; do
  env_variable_name="${f##*/}"
  # FIXME: Remove UID check?
  _TEMP_VAR=`cat $f`
#   echo "${env_variable_name}=${_TEMP_VAR}"
  cat <<EOF >> /home/pi/bash_generated_goss.yaml
  cat /var/run/s6/container_environment/${env_variable_name}:
    exit-status: 0
    stdout:
      - '$_TEMP_VAR'
EOF

done


# validate it looks good visually
cat /home/pi/bash_generated_goss.yaml
```

*echo tests:*

```
# This one creates the cat /var/run/s6/container_environment/{VAR_NAME} tests
# Create goss test file
touch /home/pi/bash_generated_goss.yaml
cat <<EOF > /home/pi/bash_generated_goss.yaml
command:
EOF

# validate it looks good visually
cat /home/pi/bash_generated_goss.yaml

# Begin segment to generate it dynamically
CONTAINER_ENV_LOC=/var/run/s6/container_environment/*

# env var check
for f in $CONTAINER_ENV_LOC; do
  env_variable_name="${f##*/}"
  # FIXME: Remove UID check?
  _TEMP_VAR=`cat $f`
#   echo "${env_variable_name}=${_TEMP_VAR}"
  cat <<EOF >> /home/pi/bash_generated_goss.yaml
  echo \$${env_variable_name}:
    exit-status: 0
    stdout:
      - '$_TEMP_VAR'
EOF

done


# validate it looks good visually
cat /home/pi/bash_generated_goss.yaml
```


# ./helper script and generic shell scripting stuff

*source: https://github.com/just-containers/s6-overlay/pull/53/files*

### Loading environment variables

 If you'd like to write a shell script that references environment variables, use the `with-contenv` utility like so:

 ```sh
 #!/usr/bin/with-contenv sh

 printenv
 ```

 ### Writing environment variables

 To write any new environment variables, use the `set-contenv` utility like so:

 ```sh
 #!/usr/bin/with-contenv sh

 set-contenv ENV_VAR_NAME env_var_value
 ```

 The next time your script runs with `with-contenv`, your new environment variable will exist.

*feedback from skarnet (Laurent Bercot):*

```
Honestly, I don't really know what to say: you guys are talking about heavy services and complex stuff I know nothing about, so you have the expertise here, not I.
As far as design is concerned, here's my point of view, but keep in mind that it's theoretical, and your practical quality of life should override it:

*   I think it's probably important to keep the "container environment", i.e. the variables defined outside the container, separate from the "dynamic environment", i.e. the variables that may be added or modified inside the container. If I were to implement an environment-based solution to [@smebberson](https://github.com/smebberson) 's problem, I would not touch the container environment, but use a second envdir, and provide a `with-dynenv` command that would just `s6-envdir` it, to add the dynamic environment to the current one; so `with-contenv foobar` would be reproducible, and `with-contenv with-dynenv foobar` would be flexible.
*   I use the environment heavily because it's the easiest way to transfer data across components of a command line, and my favorite programming paradigm precisely involves small components, long command lines, and a lot of communication between various small processes. That is how execline and s6 work, and since those are the heart of the overlay, it makes sense to use envdirs for the overlay's configuration.
    However, when you have a long-lived process that maintains a lot of internal state and that you cannot easily re-exec, such as a heavy daemon like the ones you guys are using, then the environment is only good for its initial configuration. Since it can only be re-read by re-exec'ing, it's a poor mechanism for dynamic transmission of information; heavy daemons usually have their own mechanisms to dynamically read configuration information without having to restart entirely. For instance, a standard Unix convention is that receiving a SIGHUP makes a daemon read its config file again.

So, I have no idea what mechanisms are available to Node.js, or consul, or whatever, but my uninformed opinion is that you should try and take advantage of them, and if it's not an option, then you should probably keep your changes in a separate envdir and read them in addition to the container environment when you (re)start your app.
```


# aclocal + autoreconf problem

*When this is defined:*

```
*** Configuring gtk-doc *** [1/1]
/home/pi/gnome/gtk-doc/autogen.sh --prefix /home/pi/jhbuild --disable-Werror  PYTHON=/usr/bin/python3
autoreconf: Entering directory `.'
autoreconf: configure.ac: not using Gettext
autoreconf: running: aclocal --force -I m4 ${ACLOCAL_FLAGS}
aclocal: error: couldn't open directory '/home/pi/jhbuild/share/aclocal': No such file or directory
autoreconf: aclocal failed with exit status: 1
*** Error during phase configure of gtk-doc: ########## Error running /home/pi/gnome/gtk-doc/autogen.sh --prefix /home/pi/jhbuild --disable-Werror  PYTHON=/usr/bin/python3  *** [1/1]
*** the following modules were not built *** [1/1]
gtk-doc
ERROR: Service 'jhbuild_pygobject3' failed to build: The command '/bin/sh -c bash /home/pi/.local/bin/compile_jhbuild_and_deps.sh' returned a non-zero code: 1
```


# awk magic

*given:*

```
/tests/goss.d/jhbuild/python3.yaml
/tests/goss.d/jhbuild/gnome_file_permissions.yaml
/tests/goss.d/jhbuild/jhbuild_file_permissions.yaml
/tests/goss.d/jhbuild/commands.yaml
/tests/goss.d/shell/env_vars.yaml
/tests/goss.d/s6/env_vars_container_environment.yaml
/tests/goss.d/user/user.yaml
/tests/goss.d/user/file_permissions.yaml
/tests/goss.d/hosts/hostname.yaml
/tests/goss.d/services/dbus.yaml
/tests/goss.d/packages/xenial.yaml
/tests/goss.python3.yaml
/tests/goss.jhbuild.yaml
```

# install sphinx osx

re: https://github.com/vscode-restructuredtext/vscode-restructuredtext/blob/master/docs/sphinx.md

`ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip3 install sphinx sphinx-autobuild`


# tested apt-fast w/ this ( assume vanilla xenial )

```
# Prepare packaging environment
export DEBIAN_FRONTEND=noninteractive

# make apt use ipv4 instead of ipv6 ( faster resolution )
sed -i "s@^#precedence ::ffff:0:0/96  100@precedence ::ffff:0:0/96  100@" /etc/gai.conf && apt-get update

# Install language pack before setting env vars to utf-8

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
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ensure local python is preferred over distribution python
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

apt-get update && \
apt-get install -y software-properties-common && \
add-apt-repository -y ppa:saiarcot895/myppa < /dev/null && \
apt-get update && \
echo debconf apt-fast/maxdownloads string 16 | debconf-set-selections; \
echo debconf apt-fast/dlflag boolean true | debconf-set-selections; \
echo debconf apt-fast/aptmanager string apt-get |  debconf-set-selections; \
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-fast && \
apt-fast update
```


# EnvironmentVariables ubuntu default

```
root@scarlett-travis:/etc# cat /etc/environment
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
root@scarlett-travis:/etc#
```
