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
  type = string
}

variable "iso_urls" {
  type = list(string)
}

variable "iso_checksum" {
  type = string
}

variable "cpus" {
  type = string
}

variable "memory" {
  type = string
}

variable "disk_size" {
  type = string
}

variable "hcp_client_id" {
  type    = string
  default = "${env("hcp_client_id") != "" ? env("hcp_client_id") : "unset"}"
}

variable "hcp_client_secret" {
  type    = string
  default = "${env("hcp_client_secret") != "" ? env("hcp_client_secret") : "unset"}"
}

variable "vagrant_cloud_user" {
  type    = string
  default = "${env("vagrant_cloud_user") != "" ? env("vagrant_cloud_user") : "unset"}"
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
  default     = "$6$5rFpim1KqZfBwzhD$XIwSTmg2rjrzFSX9qcBUs2atswKmwHvMz4RZS8Cmb7gMf5ZmSpcv7q.G3.FW/K5adDoc6BwQSaGxuyBd25gl21"
}

variable "switch_name" {
  type    = string
  default = "Default switch"
}

variable "hyperv_configuration_version" {
  type    = string
  default = "11.0"
}