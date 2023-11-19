# Arch Linux ARM Cloud Image

Work in progress.

Inspired by:

- [`archlinux/arch-boxes`](https://github.com/archlinux/arch-boxes)
- [`mginty/arch-boxes-arm`](https://github.com/mcginty/arch-boxes-arm)

Meant to be built in a x86-64 Arch Linux host with `binfmt_misc` support for `aarch64`.

## Motivation

Lima's [Arch Linux support for ARM](https://github.com/lima-vm/lima/blob/a21b5f3bbcb63a37987a328e63d8a1a9f1c2e098/examples/archlinux.yaml#L7)
is old and does not work with macOS's Virtualization framework backend (`vz`).

This probably happens because the Virtualization framework EFI firmware doesn't
handle the `startup.nsh` file [that the current image uses](https://github.com/lima-vm/lima/issues/858#issuecomment-1146682322).

This is an attempt of adding support for `vz`, and also to have a build script
that can be used more easily from a x86-64 Arch Linux host
(using `qemu-user-static-binfmt` instead of depending on a VM or native `aarch64`
machine).

## Requirements

```shell
sudo pacman -S qemu-user-static-binfmt gptfdisk
```

## Remaining tasks

- [ ] Refactor script with better error handling.
- [ ] Investigate ramdom freezes when the VM is running under `vz`.
