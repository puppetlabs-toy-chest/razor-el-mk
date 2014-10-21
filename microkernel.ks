# Kickstart file to build a small Fedora image
# This is based on the work at http://www.thincrust.net
# Also based on https://git.fedorahosted.org/cgit/cloud-kickstarts.git/tree/container/container-small-19.ks
lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC
auth --useshadow --enablemd5
selinux --permissive
bootloader --timeout=1 --append="acpi=force"

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
repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-19&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f19&arch=$basearch
repo --name=puppetlabs-products --baseurl=http://yum.puppetlabs.com/fedora/f19/products/$basearch
repo --name=puppetlabs-deps --baseurl=http://yum.puppetlabs.com/fedora/f19/dependencies/$basearch

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
# RAZOR-145 Add dmidecode for facter support
dmidecode
# Additional dependency for facter support
virt-what

# Only needed because livecd-tools runs /usr/bin/firewall-offline-cmd
# unconditionally; patch submitted upstream. Remove once released version
# with it is available
firewalld

# SSH access
openssh-clients
openssh-server

# In order to have network connections managed effectively, we use
# NetworkManager.  This is ~ 5.9MB of space in the image, but it also means
# that we are (A) using the recommended and default upstream configuration,
# and (B) no longer responsible for doing all the network management
# ourselves.  This is, overall, a big win for everyone.
#
# Also, this opens the door to allowing for more complex configurations such
# as 802.1x secured network links, VPN connectivity for communication with the
# host, and so forth -- should we decide we need it.
#
# Ultimately, though, that as the upstream project write:
#
#    "Fedora now by default relies on NetworkManager for network
#     configuration. This is the case also for minimal installations and server
#     installations. We are trying to make NetworkManager as suitable for this
#     task as possible."
#
# I hope that doesn't offend.  Dropping this in just works! --daniel 2013-11-07
NetworkManager

# Used to update code at runtime
unzip

# Enable stripping
binutils

# We need a ruby env and all of facter's dependencies fulfilled
rubygems
facter
net-tools

#
# Packages to Remove
#
-prelink
-setserial
-ed
-tar

# Remove the authconfig pieces
-authconfig
-wireless-tools
-passwd

# Remove the kbd bits
-kbd
-usermode

# file system stuff
-kpartx
-dmraid
-mdadm
-lvm2
-e2fsprogs
-e2fsprogs-libs

# grub
-freetype
-grub2
-grub2-tools
-grubby
-os-prober

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
# ensure we don't have the same random seed on every image, which
# could be bad for security at a later point...
echo " * purge existing random seed to avoid identical seeds everywhere"
rm -f /var/lib/random-seed

# I can't tell if this should force a new SSH key, or force a fixed one,
# but for now we can ensure that we generate new keys when SSHD is finally
# fined up on the nodes...
#
# We also disable SSHd automatic startup in the final image.
echo " * disable sshd and purge existing SSH host keys"
rm -f /etc/ssh/ssh_host_*key{,.pub}
systemctl disable sshd.service

echo " * removing python precompiled *.pyc files"
find /usr/lib64/python*/ -name *pyc -print0 | xargs -0 rm -f

# This seems to cause 'reboot' resulting in a shutdown on certain platforms
# See https://tickets.puppetlabs.com/browse/RAZOR-100
echo " * disable the mei_me module"
mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/mei.conf <<EOMEI
blacklist mei_me
install mei_me /bin/true
blacklist mei
install mei /bin/true
EOMEI

echo " * compressing cracklib dictionary"
gzip -9 /usr/share/cracklib/pw_dict.pwd

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
    firewalld libselinux-python python-decorator \
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
