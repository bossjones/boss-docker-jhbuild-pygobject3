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
