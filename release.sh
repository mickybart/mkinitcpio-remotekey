#!/usr/bin/env bash

VERSION=$1
TGZ=releases/v$VERSION.tar.gz

# create archive and sign it
mkdir -p releases
tar -czf $TGZ -C ./initcpio . ../COPYING
gpg -u F9E8AF21879815B6 -b -s $TGZ

# update PKGBUILD
CHECKSUM=$(sha512sum $TGZ | awk '{print $1}')
sed -i "s|^pkgrel=.*|pkgrel=1|;s|^pkgver=.*|pkgver=$VERSION|" package/PKGBUILD
sed -i "s|^sha512sums=.*|sha512sums=('$CHECKSUM'|" package/PKGBUILD
