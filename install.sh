#!/bin/sh

scp -r build/2.0/ScreenSplitr.app root@192.168.1.101:/Applications
ssh root@192.168.1.101 "~/patch.sh"

