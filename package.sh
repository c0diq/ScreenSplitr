#!/bin/sh

rm -rf package/ScreenSplitr/Applications/ScreenSplitr.app/

ssh root@192.168.1.101 "ldid -S /Applications/ScreenSplitr.app/ScreenSplitr"
scp -r root@192.168.1.101:/Applications/ScreenSplitr.app package/ScreenSplitr/Applications

cd package

dpkg-deb -b ScreenSplitr deb/screensplitr.deb
dpkg-scanpackages deb /dev/null > Packages
bzip2 -fks Packages

scp Packages.bz2 soothe@plutinosoft.com:~/plutinosoft.com/cydia
scp -r deb soothe@plutinosoft.com:~/plutinosoft.com/cydia

cd ..

