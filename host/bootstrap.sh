#!/bin/bash

# Run from inside the "host" build context

set -x
set -e

# Bootstrap the system
sed -i 's/CheckSpace/#CheckSpace/' /etc/pacman.conf
pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu --needed --noconfirm arch-install-scripts
pacstrap -c /mnt base linux-aarch64 grub efibootmgr openssh sudo btrfs-progs cloud-utils parted sudo sshfs

# Install cloud-init (not in the ALARM repo)
curl -L https://archlinux.org/packages/extra/any/cloud-init/download -o /mnt/root/cloud-init.pkg.tar.zst
arch-chroot /mnt /usr/bin/pacman -U --noconfirm /root/cloud-init.pkg.tar.zst
rm /mnt/root/cloud-init.pkg.tar.zst

# Tweak from arch-boxes
rm /mnt/etc/machine-id

arch-chroot /mnt /usr/bin/btrfs subvolume create /swap
chattr +C /mnt/swap
chmod 700 /mnt/swap
fallocate -l 512M /mnt/swap/swapfile
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile

# Configure fstab
root_partuuid=$(findmnt -fn -o PARTUUID /mnt)
efi_partuuid=$(findmnt -fn -o PARTUUID /mnt/boot)
cat <<EOF >"/mnt/etc/fstab"
/dev/disk/by-partuuid/${root_partuuid} / btrfs compress=zstd 0 1
/dev/disk/by-partuuid/${efi_partuuid} /boot vfat defaults 0 2
swap /swap/swapfile none defaults 0 0
EOF

arch-chroot /mnt /usr/bin/systemd-firstboot --timezone=UTC --hostname=alarm --keymap=us

cat <<EOF >"/mnt/etc/systemd/system/pacman-init.service"
[Unit]
Description=Initializes Pacman keyring
Before=sshd.service cloud-final.service archlinux-keyring-wkd-sync.service
After=time-sync.target
ConditionFirstBoot=yes

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/pacman-key --init
ExecStart=/usr/bin/pacman-key --populate archlinuxarm

[Install]
WantedBy=multi-user.target
EOF

# Enable services
arch-chroot /mnt /bin/bash -e <<EOF
source /etc/profile
systemctl enable sshd
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd
systemctl enable systemd-time-wait-sync
systemctl enable pacman-init.service
systemctl enable cloud-init-local.service
systemctl enable cloud-init.service
systemctl enable cloud-config.service
systemctl enable cloud-final.service
EOF

# Setup GRUB
mkdir /mnt/boot/EFI
arch-chroot /mnt /usr/bin/grub-install --removable --efi-directory=/boot --boot-directory=/boot --no-nvram --target=arm64-efi
sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=1/' /mnt/etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX=.*$/GRUB_CMDLINE_LINUX="net.ifnames=0"/' /mnt/etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"rootflags=compress=zstd\"/' /mnt/etc/default/grub
# Setup root partition by PARTUUID (otherwise grub will try to use the device names, which are unpredictable)
echo "GRUB_DISABLE_LINUX_UUID=true" >> /mnt/etc/default/grub
echo "GRUB_DISABLE_LINUX_PARTUUID=false" >> /mnt/etc/default/grub
arch-chroot /mnt /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
