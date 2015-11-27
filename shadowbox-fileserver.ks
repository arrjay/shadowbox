#version=RHEL7
# System authorization information
auth --enableshadow --passalgo=sha512

# Use network installation
url --url="http://mirrors.kernel.org/centos/7/os/x86_64"
# Run the Setup Agent on first boot
firstboot --disable
ignoredisk --only-use=vda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate --hostname=shadowbox-fs
# Root password
rootpw --iscrypted $6$y9fGm7f8OX3zLVu/$HFmxAs2UgWpv89snjVJt.RewW0a2DMYknbJUJD85TmepIaJ1JLuetOQDEJxT7R.2KN5vq9wg4gxIX.JzTjRPE.
# System timezone
timezone America/New_York --isUtc
# System bootloader configuration
bootloader --location=mbr --boot-drive=vda
# Partition clearing information
clearpart --all --initlabel --drives=vda
# Disk partitioning information
part /boot --fstype="ext4" --ondisk=vda --size=500
part /boot/efi --fstype="efi" --ondisk=vda --size=200 --fsoptions="umask=0077,shortname=winnt"
part pv.303 --fstype="lvmpv" --ondisk=vda --size=8192 --grow
volgroup shadowbox_fs --pesize=4096 pv.303
logvol swap  --fstype="swap" --size=2048 --name=swap --vgname=shadowbox_fs
logvol /  --fstype="ext4" --size=8192 --name=root --vgname=shadowbox_fs

%packages
@core
mdadm
rsync

%end

