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
