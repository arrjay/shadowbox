#!/bin/bash

# set up network bridge
nmcli con add type bridge ifname br0
nmcli con modify bridge-br0 bridge.stp no
nmcli con modify bridge-br0 bridge.forward-delay 2
nmcli con add type bridge-slave ifname enp7s0 master bridge-br0
nmcli con delete enp7s0

# install avahi for discovery
yum -y install avahi

# install handy software
yum -y install htop screen dstat smartmontools

# install hardware id utilities
yum -y install lsscsi pciutils usbutils dmidecode

# set up pci-stub
# NOTE: you have to hand devices out by iommu group
# (see /sys/kernel/iommu_groups/*/devices)
# so actually using this is...board-dependent.
# I'm using a ASRock FM2A85X Extreme6.
# as far as I can tell, pre-assigning some devices that share a pci id with
# devices you want to use isn't easily doable, you will need hotplug there.
# Group 2 (PCI Bridge 00:02.0)
# 01:00.0 - 1002:6749 (AMD Barts XT)
# 01:00.1 - 1002:aa90 (AMD Barts HDMI Audio)
# Group 3 (PCI Bridge 00:03.0)
# 02:00.0 - 1b73:1100 (Fresco Logic FL1100 USB 3.0 Host Controller)
# Group 4 (PCI Bridge 00:04.0)
# 03:00.0 - 1b4b:9230 (Marvell Technology Group SATA 6GB/s Controller)
grubby --args="pci-stub.ids=1002:6738,1002:aa88,1b73:1100,1b4b:9230" --update-kernel $(grubby --default-kernel)

# install libvirt, qemu, so on
yum -y install libvirt qemu-kvm virt-install

# https://fedoraproject.org/wiki/Using_UEFI_with_QEMU
curl https://www.kraxel.org/repos/firmware.repo -o /etc/yum.repos.d/firmware.repo
yum install edk2.git-ovmf-x64
printf 'nvram = [\n\t"/usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd:/usr/share/edk2.git/ovmf-x64/OVMF_VARS-pure-efi.fd",\n]\n' >> /etc/libvirt/qemu.conf

# https://fedoraproject.org/wiki/Windows_Virtio_Drivers
curl https://fedorapeople.org/groups/virt/virtio-win/virtio-win.repo -o /etc/yum.repos.d/virtio-win.repo
yum install virtio-win

# RAID utilities
yum -y install mdadm

# create libvirt_images fs
lvcreate -nlibvirt_images -L8G fedora_shadowbox
mkfs.ext4 /dev/fedora_shadowbox/libvirt_images
printf '/dev/mapper/fedora_shadowbox-libvirt_images /var/lib/libvirt/images ext4 defaults 1 2\n' >> /etc/fstab

# steps creating the initial vms
## for windows - make a RAID0 stripe to use
# mdadm --create /dev/md0 --metadata 1.2 --level=stripe --raid-devices=2 /dev/sdb /dev/sdc
# virt-install --name windows --ram 12288 --disk /dev/md0,cache=none --cdrom /var/lib/libvirt/images/IR3_CENA_X64FREV_EN-US_DV9.iso --memorybacking nosharepages=on --graphics vnc --boot uefi --vcpus 2
# (in the vm)
#  fd0:
#  cd efi\boot
#  bootx64.efi
# press a key if needed.

## the fileserver lives in a logical volume, go make that
# lvcreate -nfileserver -L18G fedora_shadowbox
# virt-install --name fileserver --ram 1536 --disk /dev/fedora_shadowbox/fileserver --network bridge=br0 --graphics vnc --memorybacking nosharepages=on -l http://mirrors.kernel.org/centos/7/os/x86_64/ --boot uefi --extra-args "ks=http://172.16.128.80/ks/shadowbox-fileserver.ks"
