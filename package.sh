#!/bin/sh

cd package
rm -rf /tmp/ScreenSplitr
rm -rf deb
mkdir /tmp/ScreenSplitr
mkdir /tmp/ScreenSplitr/Applications
mkdir /tmp/ScreenSplitr/DEBIAN
cp control /tmp/ScreenSplitr/DEBIAN
mkdir deb

cp -r ../build/3.0/ScreenSplitr.app /tmp/ScreenSplitr/Applications

dpkg-deb -b /tmp/ScreenSplitr deb/screensplitr.deb
dpkg-scanpackages deb /dev/null > Packages
bzip2 -fks Packages

cd ..

