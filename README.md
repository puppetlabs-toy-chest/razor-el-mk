# El Microkernel

This repository has the files/tools for building a Razor Microkernel based
on RHEL/CentOS/Fedora.

To build an image, run the following on a Fedora 18 machine:

    > sudo livecd-creator --verbose --config fedora-aos.ks

This will produce an ~ 150MB ISO file. You can extract kernel and initrd
with

    > sudo livecd-iso-to-pxeboot ./livecd-fedora-aos-*.iso

For more information on these tools, see the [Fedora Live CD page](https://fedoraproject.org/wiki/How_to_create_and_use_a_Live_CD?rd=How_to_create_and_use_Fedora_Live_CD)

## Todo

* Port fedora-aos.ks to CentOS/RHEL (mostly a matter of changing repos)
* Insert new Razor MK client (still to be written)
* Have fun trying to minimize the image
