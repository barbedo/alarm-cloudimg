#!/bin/bash

set -x

# Check if running as root
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

# Option: pass -f to also remove the downloded alarm file
if [ "$1" == "-f" ]; then
    rm -rf build/ArchLinuxARM-aarch64-latest.tar.gz
fi

rm -rf build/{alarm,image.img,ArchLinuxARM-aarch64-cloud-init-*.qcow2}
