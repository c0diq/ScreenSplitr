#!/bin/sh

cd package
rm -rf ScreenSplitr
rm -rf deb
mkdir ScreenSplitr
mkdir ScreenSplitr/Applications
mkdir ScreenSplitr/DEBIAN
cp control ScreenSplitr/DEBIAN
mkdir deb

cp -r ../build/3.0/ScreenSplitr.app ScreenSplitr/Applications

dpkg-deb -b ScreenSplitr deb/screensplitr.deb
dpkg-scanpackages deb /dev/null > Packages
bzip2 -fks Packages

cd ..

