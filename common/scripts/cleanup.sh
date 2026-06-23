#!/bin/bash

echo "==> Removing unneeded packages"
apt-get -y autoremove --purge

echo "==> Cleaning local package repository"
apt-get -y clean

echo "==> Truncating log files"
find /var/log -type f -exec truncate -s 0 {} \;

echo "==> Removing temporary files"
find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} +
find /var/tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} +

echo "==> Zeroing out free space"
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY