# Dockerfile Snippets

*source:https://github.com/Thell/dockerfiles/blob/b483dfed7c7d4ae43cbdf8389a57e5c3ead68444/NOTES.md*

## Pandoc local build

````{bash}
# install haskell-platform then ...
cabal update; \
cabal install -j pandoc pandoc-citeproc; \
ln -s -t ~/.local/bin ~/.cabal/bin/*; \
mkdir -p .local/lib/pandoc/templates; \
ln -s .local/lib/pandoc .pandoc
````

## Latest JQ

````{bash}
RUN \
URL=https://api.github.com/repos/stedolan/jq/releases/latest; \
curl -o jq -L \
  $(curl -sS ${URL} | jq -r '.assets|.[]|select(.name == "jq-linux64")|.browser_download_url'); \

chmod +x jq; \
mv -f jq /usr/bin/jq;
````

## R ccache setup

````
echo "CC=ccache gcc\nCXX=ccache g++\nCFLAGS+=-std=c11\nCXXFLAGS+=-std=c++11\n" > ~/.config/R/Makevars; \
````

## GNU Parallel

Install and ...

````{bash}
echo "--no-notice" > /etc/parallel/config; \
````

## Node Repo and key

````
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68576280
RUN apt-add-repository -s "deb https://deb.nodesource.com/node_0.12 vivid main"
````

## apt-fast

````
RUN \
echo "apt-fast apt-fast/maxdownloads string 5" | debconf-set-selections; \
echo "apt-fast apt-fast/dlflag boolean true" | debconf-set-selections; \
apt-get -qq --no-install-recommends install	apt-fast
````

## apt-fast aria2 config

````
RUN \
# apt-fast aria2 command setup
sed -i'' "/^_DOWNLOADER=/ s/-m0/-m0 \
 --quiet \
 --console-log-level=error \
 --show-console-readout=false \
 --summary-interval=10 \
 --enable-rpc \
 --on-download-stop=apt-fast-progress/" /etc/apt-fast.conf
````

## C++ compiler repos

````
# GCC repository
apt-add-repository -ys ppa:ubuntu-toolchain-r/test; \

# LLVM repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AF4F7421; \
apt-add-repository -s "deb http://llvm.org/apt/vivid/ llvm-toolchain-vivid-3.7 main"
````

then update && upgrade and install

````
  build-essential \
  ccache \
  clang-3.7 \
  clang-modernize-3.7 \
  clang-format-3.7 \
  gdb \
  lldb-3.7 \
````



# apt-fast

```
# bossjones implementation

apt-get update && \
apt-get install -y software-properties-common && \
add-apt-repository -y ppa:saiarcot895/myppa && \
apt-get update && \
echo "apt-fast apt-fast/maxdownloads string 5" | debconf-set-selections; \
echo "apt-fast apt-fast/dlflag boolean true" | debconf-set-selections; \
apt-get -y install apt-fast && \
apt-fast update
```

```
# another implementation bossjones
# source: https://github.com/ilikenwf/apt-fast/issues/85

apt-get update && \
apt-get install -y software-properties-common && \
add-apt-repository -y ppa:saiarcot895/myppa < /dev/null && \
apt-get update && \
echo debconf apt-fast/maxdownloads string 16 | debconf-set-selections; \
echo debconf apt-fast/dlflag boolean true | debconf-set-selections; \
echo debconf apt-fast/aptmanager string apt-get |  debconf-set-selections; \
apt-get install -y apt-fast && \
apt-fast update
```

```
add-apt-repository ppa:saiarcot895/myppa < /dev/null
apt-get update
echo debconf apt-fast/maxdownloads string 16 | sudo debconf-set-selections
echo debconf apt-fast/dlflag boolean true | sudo debconf-set-selections
echo debconf apt-fast/aptmanager string apt-get | sudo debconf-set-selections
sudo apt-get install -y apt-fast
```

# testing on jenkins

`export NO_PROXY=* && docker-compose -f docker-compose.compile.yml -f ci_build_v2.yml up --build`

# jhbuild issues

https://wiki.gnome.org/action/show/Projects/Jhbuild/Issues?action=show&redirect=JhbuildIssues

https://wiki.gnome.org/psychoslave/installing

http://worldofgnome.org/how-to-easily-install-the-very-latest-gnome-in-any-distro-with-jhbuild/


Make sure the `PKG_CONFIG_PATH` environment variable is set correctly.

Find all the locations where .pc files are stored:

`for f in $(locate *.pc); do dirname $f; done | uniq`

For each location add it to your jhbuildrc like so:

```
addpath('PKG_CONFIG_PATH', '/directory/to/pc/files')
addpath('PKG_CONFIG_PATH', '/other/pc/files/live/here')
```
