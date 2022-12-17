#!/usr/bin/env bash
set -e

pkgver=$1
url="https://github.com/mickybart/mkinitcpio-remotekey"
tgz=$url/archive/v$pkgver.tar.gz

# prepare environment
mkdir -p releases

# download archive and sign it
curl -f -L -o releases/v$pkgver.tar.gz $tgz
gpg -u F9E8AF21879815B6 -b -s releases/v$pkgver.tar.gz

# update PKGBUILD
CHECKSUM=$(sha512sum releases/v$pkgver.tar.gz | awk '{print $1}')
sed -i "s|^pkgrel=.*|pkgrel=1|;s|^pkgver=.*|pkgver=$pkgver|" PKGBUILD
sed -i "s|^sha512sums=.*|sha512sums=('$CHECKSUM'|" PKGBUILD
