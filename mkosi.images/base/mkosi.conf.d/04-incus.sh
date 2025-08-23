#!/bin/sh -eux

# Copy apparmor configuration to /usr/share/.
mkdir -p "${DESTDIR}/usr/share/incus"
cp -r /buildroot/opt/incus/ "${DESTDIR}/usr/share/"
exit 0
