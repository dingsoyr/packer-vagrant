#!/bin/bash

# Hyper-v tools https://blog.jitdor.com/2020/02/08/enable-hyper-v-integration-services-for-your-ubuntu-guest-vms/
echo "==> Add hyper-v tools"
echo 'hv_utils' >> /etc/initramfs-tools/modules
echo 'hv_vmbus' >> /etc/initramfs-tools/modules
echo 'hv_storvsc' >> /etc/initramfs-tools/modules
echo 'hv_blkvsc' >> /etc/initramfs-tools/modules
echo 'hv_netvsc' >> /etc/initramfs-tools/modules
update-initramfs -u
