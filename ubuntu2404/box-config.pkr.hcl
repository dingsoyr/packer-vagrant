packer {
  required_version = ">= 1.7.0"
  required_plugins {
    hyperv = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/hyperv"
    } 
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }       
  }
}

variable "name" {
  type    = string
  default = "ubuntu2404"
}

variable "iso_urls" {
  type    = list(string)
  default = ["iso/ubuntu-24.04.3-live-server-amd64.iso", "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"]
}

variable "iso_checksum" {
  type    = string
  default = "c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
}

# Variable cant be dynamic, using local instead
locals {
  version = formatdate("YYYY.MM.DD.hh", timestamp())
}

variable "hcp_client_id" {
  type    = string
  default = "${env("hcp_client_id")}"
}

variable "hcp_client_secret" {
  type    = string
  default = "${env("hcp_client_secret")}"
}

variable "username" {
  type    = string
  default = "vagrant"
}

variable "password" {
  type    = string
  default = "vagrant"
}

variable "crypted_password" {
  type        = string
  description = "openssl passwd -6 password. must match password from above."
  default     = "$6$5rFpim1KqZfBwzhD$XIwSTmg2rjrzFSX9qcBUs2atswKmwHvMz4RZS8Cmb7gMf5ZmSpcv7q.G3.FW/K5adDoc6BwQSaGxuyBd25gl21" #vagrant
}

variable "cpus" {
  type    = string
  default = "2"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "disk_size" {
  type    = string
  default = "131072"
}

# Build the VM with the Ubuntu ISO
source "hyperv-iso" "efi" {
  boot_command         = [
    "c<wait>linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<enter><wait5s>initrd /casper/initrd <enter><wait5s>boot <enter><wait5s>"
  ]
  boot_wait             = "1s"
  communicator          = "ssh"
  vm_name               = "packer-${var.name}"
  cpus                  = "${var.cpus}"
  memory                = "${var.memory}"
  disk_size             = "${var.disk_size}"
  iso_urls              = "${var.iso_urls}"
  iso_checksum          = "${var.iso_checksum}"
  headless              = false
  #http_directory        = "http"
  ssh_username          = "${var.username}"
  ssh_password          = "${var.password}"
  ssh_port              = 22
  ssh_timeout           = "3600s"
  enable_dynamic_memory = false
  #enable_secure_boot    = false
  guest_additions_mode  = "disable"
  switch_name           = "Default switch"
  generation            = "2"
  #secure_boot_template  = "MicrosoftUEFICertificateAuthority"
  configuration_version = "11.0"
  output_directory      = "builds/${var.name}"
  shutdown_command      = "echo '${var.password}' | sudo -S shutdown -P now"
  http_content = {
    "/user-data" = templatefile("./templates/user-data.pkr.hcl", {
      username        = var.username
      password        = var.crypted_password
      hostname        = var.name
    })
    "/meta-data" = ""
  }  
  first_boot_device     = "DVD"
  boot_order            = ["DVD", "SCSI:0:0", "NET"]  
}

# Build the box and package it as a Vagrant box
build {
  name = "build"

  sources = ["hyperv-iso.efi"]

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{ .Vars }} sudo -S -E bash {{ .Path }}"
    pause_before    = "1s"
    scripts         = [
      "scripts/vagrant.sh",
      "scripts/hyperv.sh",
      "scripts/cleanup.sh"
    ]
  }

  post-processors {
    post-processor "shell-local" {
      inline = [
        "powershell.exe -Command \"if (Test-Path -Path 'builds/${var.name}_sha256.checksum') { Remove-Item -Path 'builds/${var.name}_sha256.checksum' -Force }\"",
        "powershell.exe -Command \"if (Test-Path -Path 'builds/${var.name}.box') { Remove-Item -Path 'builds/${var.name}.box' -Force }\""
      ]
    }
    post-processor "vagrant" {
      compression_level = 9
      keep_input_artifact = false
      output = "builds/${var.name}.box"
      vagrantfile_template = "templates/vagrantfile.rb"
      include = ["templates/info.json"]
      architecture = "amd64"
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output = "builds/${var.name}_sha256.checksum"
    }
  }
}

# Dummy source for build step. It does nothing, but is required for the post-processor to work.
source "null" "core" {
    communicator = "none"
}

# Publish the box to Vagrant Cloud
build {
  name = "publish"

  sources = ["null.core"]

  post-processors {
    post-processor "artifice" {
      files = ["builds/${var.name}.box"]
    }
    post-processor "vagrant-registry" {
      client_id     = "${var.hcp_client_id}"
      client_secret = "${var.hcp_client_secret}"
      box_tag      = "sture/${var.name}"
      version      = "${local.version}"
      architecture = "amd64"
      box_checksum = fileexists("builds/${var.name}_sha256.checksum") ? "SHA256:${split("\t", file("builds/${var.name}_sha256.checksum"))[0]}" : ""
    } 
  }
}