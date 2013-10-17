# Kickstart file to build a small Fedora image
# This is based on the work at http://www.thincrust.net
# Also based on https://git.fedorahosted.org/cgit/cloud-kickstarts.git/tree/container/container-small-19.ks
lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC
auth --useshadow --enablemd5
selinux --permissive
bootloader --timeout=1 --append="acpi=force"
# we don't want network auto-configured -- udev does that on boot!
# network --bootproto=dhcp --device=eth0 --onboot=on
services --enabled=network

# Uncomment the next line
# to make the root password be thincrust
# By default the root password is emptied
rootpw --iscrypted $1$uw6MV$m6VtUWPed4SqgoW6fKfTZ/

#
# Partition Information. Change this as necessary
# This information is used by appliance-tools but
# not by the livecd tools.
#
part / --size 1024 --fstype ext4 --ondisk sda

#
# Repositories
#
#repo --name=rawhide --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=rawhide&arch=$basearch
# These repos work on my Fedora 18 machine (i.e., $releasever=18, $basearch=x86_64)
# For other variants, they may have to be adjusted moderately
repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch

#
# Add all the packages after the base packages
#
%packages --excludedocs --nobase
bash
kernel
grub2
e2fsprogs
passwd
policycoreutils
chkconfig
rootfiles
yum
vim-minimal
acpid
##needed to disable selinux
##lokkit

# Only needed because livecd-tools runs /usr/bin/firewall-offline-cmd
# unconditionally; patch submitted upstream. Remove once released version
# with it is available
firewalld

# SSH access
openssh-clients
openssh-server

#Allow for dhcp access
dhclient
iputils

# Enable stripping
binutils

# We need a ruby env and all of facter's dependencies fulfilled
rubygems
facter

#
# Packages to Remove
#

-prelink
-setserial
-ed

# Remove the authconfig pieces
-authconfig
-wireless-tools

# Remove the kbd bits
-kbd
-usermode

-kpartx
-dmraid
-mdadm
-lvm2
-tar

# selinux toolchain of policycoreutils, libsemanage, ustr
-policycoreutils
-checkpolicy
-selinux-policy*
-libselinux-python
-libselinux

# Things it would be nice to loose
-fedora-logos
generic-logos
-fedora-release-notes
%end

# Install the microkernel agent
%include mk-install.ks

# Try to minimize the image a bit
%post
# 100MB of locale archive is kind unnecessary; we only do en_US.utf8
# this will clear out everything we don't need; 100MB => 2.1MB.
echo " * minimizing locale-archive binary / memory size"
localedef --list-archive | grep -iv 'en_US' | xargs localedef -v --delete-from-archive
mv /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
/usr/sbin/build-locale-archive

# remove things only needed during the build process
echo " * purging packages needed only during build"
yum -C -y --setopt="clean_requirements_on_remove=1" erase \
    binutils syslinux mtools acl ebtables \
    firewalld dbus-glib libselinux-python gobject-introspection python-decorator \
    dracut xz hardlink kpartx \
    passwd

echo " * purging all other locale data"
rm -rf /usr/share/locale/*

echo " * cleaning up yum cache, etc"
yum clean all

echo " * truncating various logfiles"
for log in yum.log dracut.log lastlog yum.log; do
    truncate -c -s 0 /var/log/${log}
done

echo " * removing /boot, since that lives on the ISO side"
rm -rf /boot/*
%end

%post --nochroot
echo " * disquieting the microkernel boot process"
sed -i -e's/ rhgb//g' -e's/ quiet//g' $LIVE_ROOT/isolinux/isolinux.cfg
%end

# Network configuration
%include mk-network.ks
