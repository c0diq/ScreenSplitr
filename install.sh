#!/bin/sh

ip=$1
if [ -z $ip ]; then
    ip=192.168.1.101
fi
make
scp -r build/2.0/ScreenSplitr.app root@$ip:/Applications
ssh root@$ip "ldid -S /Applications/ScreenSplitr.app/ScreenSplitr;restart"

