#!/bin/bash

echo "==> Standardize network naming to eth0"
if grep -q '^GRUB_CMDLINE_LINUX=' /etc/default/grub; then
	if ! grep -q 'net.ifnames=0 biosdevname=0' /etc/default/grub; then
		sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 /' /etc/default/grub
	fi
else
	echo 'GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"' >> /etc/default/grub
fi

update-grub