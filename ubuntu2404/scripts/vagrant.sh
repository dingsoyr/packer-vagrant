#!/bin/bash

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

# Set up sudo
echo "==> Giving ${SSH_USER} sudo powers"
echo "${SSH_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/$SSH_USER
chmod 440 /etc/sudoers.d/$SSH_USER

echo "==> Installing vagrant key"
mkdir -pm 700 $SSH_USER_HOME/.ssh
wget --no-check-certificate https://raw.githubusercontent.com/hashicorp/vagrant/refs/heads/main/keys/vagrant.pub.rsa -O ${SSH_USER_HOME}/.ssh/authorized_keys
chmod 0600 ${SSH_USER_HOME}//.ssh/authorized_keys
chown -R ${SSH_USER}:${SSH_USER} ${SSH_USER_HOME}//.ssh
