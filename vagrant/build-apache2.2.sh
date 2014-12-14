#!/bin/sh

set -e
set -x

source /vagrant/vagrant/install-facter.sh

version='2.2.29'
release='0'

# 古いバージョンでビルドしたい場合は http://archive.apache.org/dist/httpd/ に向けてください
httpd_source="http://ftp.kddilabs.jp/infosystems/apache/httpd/httpd-${version}.tar.gz"
mod_extract_forwarded_source='http://www.openinfo.co.uk/apache/extract_forwarded-2.0.2.tar.gz'

platform=$(
    arch=$( facter architecture )
    os=$( facter operatingsystem )
    release=$( facter operatingsystemrelease)
    echo ${os}${release%.?}-${arch}
)

prefix="/usr/local/apache2"
tarball="/vagrant/apache-${version}-${release}-${platform}.tar.gz"

build_httpd() {
    yum -y install patch openssl-devel zlib-devel
    cd /usr/local/src/
    rm -rf httpd[-_]*

    wget -O httpd.tar.gz $httpd_source
    tar xzf httpd.tar.gz
    cd $( tar tzf httpd.tar.gz | head -1 )

    ./configure \
      --prefix=$prefix \
      --enable-module=most \
      --enable-so \
      --enable-deflate=shared \
      --enable-expires=shared \
      --enable-rewrite \
      --enable-headers \
      --enable-proxy \
      --with-mpm=worker \
      --enable-suexec \
      --with-suexec-caller=zeus \
      --with-suexec-userdir=web \
      --with-suexec-docroot=/home/sites/ \
      --with-suexec-logfile=/usr/local/apache2/logs/suexec_log \
      --with-suexec-uidmin=100 \
      --with-suexec-gidmin=100 \
      --enable-ssl=static

    make -j $( getconf _NPROCESSORS_ONLN )
    make install
    : httpd build funished
}

build_mod_extract_forwarded() {
    cd /usr/local/src/
    rm -rf mod[-_]extrac_forwardedt*

    wget -O mod_extract_forwarded.tar.gz $mod_extract_forwarded_source
    tar xzf mod_extract_forwarded.tar.gz
    cd $( tar tzf mod_extract_forwarded.tar.gz | head -1 )
    $prefix/bin/apxs -c -i mod_extract_forwarded.c
    : mod_extract_forwarded build finished
}

cleanup() {
    cd $prefix
    rm -rf conf
    rm -rf cgi-bin
    rm -rf htdocs
    rm -rf manual
    rm -rf man
}

yum -y install gcc make wget libtool git
:
rm -rf $prefix
mkdir -p $prefix
:
build_httpd
:
build_mod_extract_forwarded
:
cleanup
:
cd $( dirname $prefix )
tar czf $tarball $( basename $prefix )
:
: ----------------------------------------------------
: Completed successfully.
