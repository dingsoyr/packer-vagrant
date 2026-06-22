source "hyperv-iso" "efi" {
  boot_command = [
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
  ssh_username          = "${var.username}"
  ssh_password          = "${var.password}"
  ssh_port              = 22
  ssh_timeout           = "3600s"
  enable_dynamic_memory = false
  guest_additions_mode  = "disable"
  switch_name           = "${var.switch_name}"
  generation            = "2"
  configuration_version = "${var.hyperv_configuration_version}"
  output_directory      = "builds/${var.name}"
  shutdown_command      = "echo '${var.password}' | sudo -S shutdown -P now"
  http_content = {
    "/user-data" = templatefile("./common/templates/user-data.pkr.hcl", {
      username          = var.username
      password          = var.crypted_password
      hostname          = var.name
      network_interface = var.network_interface
    })
    "/meta-data" = ""
  }
  first_boot_device = "DVD"
  boot_order        = ["DVD", "SCSI:0:0", "NET"]
}

build {
  name = "build"

  sources = ["hyperv-iso.efi"]

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{ .Vars }} sudo -S -E bash {{ .Path }}"
    pause_before    = "1s"
    scripts = [
      "common/scripts/vagrant.sh",
      "common/scripts/hyperv.sh",
      "common/scripts/cleanup.sh"
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
      compression_level    = 9
      keep_input_artifact  = false
      output               = "builds/${var.name}.box"
      vagrantfile_template = "common/templates/vagrantfile.rb"
      include              = ["common/templates/info.json"]
      architecture         = "amd64"
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = "builds/${var.name}_sha256.checksum"
    }
  }
}