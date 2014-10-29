#!/bin/sh

ADD_SSL=1
ADD_IMAGE_FILTER=1 
ADD_GRIDFS=
ADD_LUA=
ADD_MEMCACHED=
ADD_UPSTREAM_HASH=
ADD_SMALL_LIGHT=
ADD_CACHE_PURGE=1

yum -y install pcre-devel

if [ $ADD_CACHE_PURGE ];then
  wget http://labs.frickle.com/files/ngx_cache_purge-2.1.tar.gz
  tar zxvf ngx_cache_purge-2.1.tar.gz
  ADD_CACHE_PURGE='--add-module=../ngx_cache_purge-2.1'
fi

if [ $ADD_SSL ];then
  ADD_SSL='--with-http_ssl_module'
fi

if [ $ADD_SMALL_LIGHT ]; then
  cd ngx_small_light && ./setup
  cd ..
  ADD_SMALL_LIGHT='--add-module=../ngx_small_light'
fi



if [ $ADD_IMAGE_FILTER ];then
  yum -y install gd-devel
  ADD_IMAGE_FILTER='--with-http_image_filter_module '
fi


if [ $ADD_GRIDFS ];then
  if [ ! -d nginx-gridfs ];  then
      git clone git://github.com/mdirolf/nginx-gridfs.git && \
      cd nginx-gridfs && \
      git submodule init && \
      git submodule update
      cd mongo-c-driver
      git checkout master
      make
      cp libmongoc.a /usr/local/lib/
      cp libmongoc.so /usr/local/lib/libmongoc.so.0.6
      /sbin/ldconfig
      cd ..
      cat <<'EOF' >config_new
ngx_addon_name=ngx_http_gridfs_module
HTTP_MODULES="$HTTP_MODULES ngx_http_gridfs_module"
NGX_ADDON_SRCS="$NGX_ADDON_SRCS $ngx_addon_dir/ngx_http_gridfs_module.c"
NGX_ADDON_DEPS="$NGX_ADDON_DEPS $ngx_addon_dir/mongo-c-driver/src/*.h"
CFLAGS="$CFLAGS --std=c99 -I src -I /usr/local/include -L /usr/local/lib -lmongoc"
EOF
      diff -u config config_new > config_patch
      patch -u < config_patch
      cd ..
  fi
  ADD_GRIDFS='--add-module=../nginx-gridfs --with-ld-opt=-lmongoc'
fi

#
# ngx_devel_kit.git for lua-nginx-module 
#

if [ $ADD_LUA ]
then

  if [ ! -d ngx_devel_kit.git ]
  then
      git clone git://github.com/simpl/ngx_devel_kit.git
      cd ngx_devel_kit && \
      git checkout v0.2.17 && \
      cd ..
  fi
  
  if [ ! -d lua-nginx-module ]
  then
      git clone git://github.com/chaoslawful/lua-nginx-module.git
      cd lua-nginx-module && \
      git checkout v0.5.7 && \
      cd ..
  fi
  
  export LUAJIT_LIB=/usr/local/luajit/lib
  export LUAJIT_INC=/usr/local/luajit/include/luajit-2.0
  ADD_DEVEL_KIT='--add-module=../ngx_devel_kit'
  ADD_LUA='--add-module=../lua-nginx-module'
fi

if [ $ADD_MEMCACHED ]
then

  if [ ! -d ngx_http_enhanced_memcached_module ]
  then
      git clone git://github.com/bpaquet/ngx_http_enhanced_memcached_module.git
  fi

  ADD_MEMCACHED='--add-module=../ngx_http_enhanced_memcached_module'
fi

VERSION=1.6.2
PREFIX=/usr/local/nginx

SRC_URL="http://nginx.org/download/nginx-$VERSION.tar.gz"

DOWNLOAD_CMD="wget"
$DOWNLOAD_CMD $SRC_URL
tar zxvf nginx-$VERSION.tar.gz
cd nginx-$VERSION

if [ $ADD_UPSTREAM_HASH ]
then
  patch -p0 < ../nginx_upstream_hash-0.3.1/nginx.patch
  ADD_UPSTREAM_HASH='--add-module=../nginx_upstream_hash-0.3.1'
fi

./configure --with-pcre --prefix=$PREFIX $ADD_CACHE_PURGE $ADD_IMAGE_FILTER $ADD_SMALL_LIGHT $ADD_SSL $ADD_GRIDFS $ADD_DEVEL_KIT $ADD_LUA $ADD_MEMCACHED $ADD_UPSTREAM_HASH --with-cc-opt=-Wno-error
make && make install 

cd ..

rm -fr nginx-$VERSION
rm -fr nginx-gridfs
rm -fr ngx_devel_kit
rm -fr lua-nginx-module
rm -fr ngx_http_enhanced_memcached_module
