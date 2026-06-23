#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: "us"
  timezone: "Etc/UTC"

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
        eth0:
          dhcp4: true

  identity:
    hostname: ${hostname}
    username: ${username}
    password: ${password}

  storage:
    layout:
      name: lvm

  packages:
    - linux-azure
    - linux-cloud-tools-azure
    - linux-tools-azure

  package_update: true
  package_upgrade: true

  late-commands:
    - curtin in-target -- update-grub
    - curtin in-target -- apt-get update
    - curtin in-target -- apt-get upgrade -y
