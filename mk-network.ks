%post
# systemd is notified at priority 99, but all other configuration of
# the network should have happened before this is triggered.  The final
# result *should* be that this runs and creates a network configuration
# file before systemd checks to act on the network configuration for
# the newly discovered interface...
#
# By restarting the networking target we help ensure that we do, in fact,
# trigger the appropriate network setup.
cat > /etc/udev/rules.d/97-write-network-configuration.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="net", RUN+="/usr/local/bin/new-net-device"
EOF

cat > /usr/local/bin/new-net-device <<'EOF'
#!/bin/bash
# we don't want to mess with loopback, thanks
test x"${INTERFACE}" = x"lo" && exit 0

# ensure that any other interface is configured via DHCP...
if ! test -f /etc/sysconfig/network-scripts/ifcfg-"${INTERFACE}"; then
    cat > /etc/sysconfig/network-scripts/ifcfg-"${INTERFACE}" <<EOT
DEVICE=${INTERFACE}
ONBOOT=on
# Both of the settings after dhcp are essential -- or else
# we "fail" if DHCP is not available on the interface, and
# consequently fail the network service, and badness follows
BOOTPROTO=dhcp
PERSISTENT_DHCLIENT=YES
IPV4_FAILURE_FATAL=NO
EOT
fi

# ...and bring it up, by asking systemd to do that for us.
# --no-block is important: otherwise we can time out waiting for the
# restart to complete, because DHCP timeouts take ages.
/bin/systemctl --no-block restart network.service
EOF

chmod +x /usr/local/bin/new-net-device
%end
