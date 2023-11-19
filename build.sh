#!/bin/bash

set -x
set -e

if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

mkdir -p build
cd build

if [ ! -f ArchLinuxARM-aarch64-latest.tar.gz ]; then
    wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
fi
mkdir -p alarm
bsdtar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C alarm

truncate -s 4G image.img
sgdisk --clear \
        --new 1::+300M --typecode=1:ef00 \
        --new 2::-0 --typecode=2:8305 \
        image.img
loopdev=$(sudo losetup --find --partscan --show image.img)

sleep 2
mkfs.vfat -F32 -n EFI ${loopdev}p1
mkfs.btrfs -L root ${loopdev}p2

mount ${loopdev}p2 alarm/mnt
mkdir alarm/mnt/boot
mount ${loopdev}p1 alarm/mnt/boot

cp ../host/bootstrap.sh alarm/root/bootstrap.sh
sudo arch-chroot alarm /root/bootstrap.sh

umount --recursive alarm/mnt
sleep 2
losetup -d ${loopdev}

build_version=$(date +%Y%m%d)
image_name="ArchLinuxARM-aarch64-cloud-init-${build_version}.qcow2"
qemu-img convert -c -f raw -O qcow2 image.img ${image_name}
