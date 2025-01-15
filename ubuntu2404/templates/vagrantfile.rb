# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

    config.vm.boot_timeout = 1800
    config.vm.synced_folder ".", "/vagrant", disabled: true
  
    config.vm.box_check_update = true
  
    config.vm.boot_timeout = 1800
    config.vm.boot_timeout = 1800
  
    config.vm.provider :hyperv do |v, override|
      v.maxmemory = 2048
      v.memory = 2048
      v.cpus = 2
    end
  
  end