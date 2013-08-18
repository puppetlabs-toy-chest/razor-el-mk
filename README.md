# El Microkernel

This repository has the files/tools for building a Razor Microkernel based
on RHEL/CentOS/Fedora.

To build an image, run the following on a Fedora 18 machine:

    > sudo livecd-creator --verbose --config microkernel.ks

This will produce an ~ 150MB ISO file. You can extract kernel and initrd
with

    > sudo livecd-iso-to-pxeboot ./livecd-microkernel-*.iso

For more information on these tools, see the [Fedora Live CD page](https://fedoraproject.org/wiki/How_to_create_and_use_a_Live_CD?rd=How_to_create_and_use_Fedora_Live_CD)

## Todo

* Port microkernel.ks to CentOS/RHEL (mostly a matter of changing repos)
* Have fun trying to minimize the image


## Razor Microkernel Client

The microkernel client has been broken out into several small, focused scripts
intended to perform one task, well.  They are designed to be fired off through
cron, or through a process scheduling supervisor.

The entry point is the binary:

 * `razor-submit-facts` will discover and send facts about the node to Razor
   - this will also act on the command returned during that action

### Razor Microkernel Client Configuration

Configuration is created by overlaying multiple sources, based on this
priority map -- lower numbers are "more important" and override higher
numbers.  The intent is that more dynamic sources of data override less
dynamic sources of data.

Sources are:

1. Kernel command line (as read from `/proc/cmdline`)
2. DHCP "next server" option (@todo danielp 2013-07-26: not implemented yet)
3. Static, on-disk configuration file (`/etc/razor-mk-client.json`)
4. A default DNS assumption that `razor` will point at your Razor server.

Any of these configuration options can be omitted with no ill effects.

In practice, the kernel command line is the place that almost all
configuration will come from.  This is set by the Razor server during boot,
automatically, to help clients that boot from it to rendezvous correctly.

The static, on-disk configuration file is not expected to be used in most
cases: this is provided as a convenience for users who, for some reason, want
to boot statically from local media rather than through the Razor server, but
still want to use the Razor MK image.  (eg: through a virtual CD device, etc.)

Configuration options are:

 * `ip` the IP address of the Razor server.
 * `server` the DNS name of the Razor server.

If supplied, the `ip` value is preferred to the `server` value for locating
the server.  Both are supported since correctly functioning DNS is not assured
during the early boot process; in general, you should strongly prefer to use the `server` value.

### Razor Microkernel Client Identification

We supply a "hardware ID" value to the Razor server to help identify the
specific hardware that is currently running: this is based on the MAC
addresses of network adapters found in the current system.

Presently that is limited only to adapters with a visible name matching
`/^eth/`, following the default naming convention for Linux wired
Ethernet adapters.

@todo danielp 2013-07-26: we should fix that, because it is too limited, and
will no longer work once F19 or F20 roll out their new "purpose and physical
location" naming convention for network adapters.
