#!/bin/bash

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}
VAGRANT_INSECURE_PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key'

echo "==> Giving ${SSH_USER} sudo powers"
echo "${SSH_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/$SSH_USER
chmod 440 /etc/sudoers.d/$SSH_USER

echo "==> Installing vagrant key"
mkdir -pm 700 $SSH_USER_HOME/.ssh
printf '%s\n' "$VAGRANT_INSECURE_PUBLIC_KEY" > ${SSH_USER_HOME}/.ssh/authorized_keys
chmod 0600 ${SSH_USER_HOME}//.ssh/authorized_keys
chown -R ${SSH_USER}:${SSH_USER} ${SSH_USER_HOME}//.ssh

echo "==> Resetting machine identity"
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id