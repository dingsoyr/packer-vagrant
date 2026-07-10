locals {
  version = var.vagrant_cloud_version != "unset" ? var.vagrant_cloud_version : formatdate("YYYY.MM.DD.hhmmss", timestamp())
}

source "null" "core" {
  communicator = "none"
}

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
      box_tag       = "${var.vagrant_cloud_user}/${var.name}"
      version       = "${local.version}"
      architecture  = "amd64"
      box_checksum  = fileexists("builds/${var.name}_sha256.checksum") ? "SHA256:${split("\t", file("builds/${var.name}_sha256.checksum"))[0]}" : ""
    }
  }
}