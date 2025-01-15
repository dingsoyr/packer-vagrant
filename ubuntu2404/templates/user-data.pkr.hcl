#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: "no"
  timezone: "Europe/Oslo"

  early-commands:
    # Prevent Packer to connect to Installer's SSH server
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
    # Hyper-v tools https://blog.jitdor.com/2020/02/08/enable-hyper-v-integration-services-for-your-ubuntu-guest-vms/
    - linux-virtual
    - linux-cloud-tools-virtual
    - linux-tools-virtual
  
  package_update: true
  package_upgrade: true

  late-commands:
    - curtin in-target -- update-grub
    - curtin in-target -- apt-get update
    - curtin in-target -- apt-get upgrade -y