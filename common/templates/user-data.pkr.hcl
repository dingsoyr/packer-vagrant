#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: "no"
  timezone: "Europe/Oslo"

  early-commands:
    - systemctl stop ssh.socket
    - systemctl stop ssh.service

  ssh:
    install-server: true
    allow-pw: true

  network:
    network:
      version: 2
      ethernets:
        ${network_interface}:
          dhcp4: true

  identity:
    hostname: ${hostname}
    username: ${username}
    password: ${password}

  storage:
    layout:
      name: lvm

  packages:
    - linux-virtual
    - linux-cloud-tools-virtual
    - linux-tools-virtual

  package_update: true
  package_upgrade: true

  late-commands:
    - curtin in-target -- update-grub
