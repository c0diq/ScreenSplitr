#!/bin/sh

ip=$1
if [ -z $ip ]; then
    ip=192.168.1.101
fi

cd package
rm -rf ScreenSplitr
rm -rf deb
mkdir ScreenSplitr
mkdir ScreenSplitr/Applications
mkdir ScreenSplitr/DEBIAN
cp control ScreenSplitr/DEBIAN
mkdir deb

ssh root@$ip "ldid -S /Applications/ScreenSplitr.app/ScreenSplitr"
scp -r root@$ip:/Applications/ScreenSplitr.app ScreenSplitr/Applications

dpkg-deb -b ScreenSplitr deb/screensplitr.deb
dpkg-scanpackages deb /dev/null > Packages
bzip2 -fks Packages

scp Packages.bz2 soothe@plutinosoft.com:~/plutinosoft.com/cydia
scp -r deb soothe@plutinosoft.com:~/plutinosoft.com/cydia

cd ..

