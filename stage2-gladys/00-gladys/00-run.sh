#!/bin/bash -e

install -m 755 files/gladys-firstboot.sh "${ROOTFS_DIR}/usr/local/sbin/gladys-firstboot"
install -m 644 files/gladys-firstboot.service "${ROOTFS_DIR}/etc/systemd/system/gladys-firstboot.service"

on_chroot << EOF
systemctl enable gladys-firstboot.service
EOF
