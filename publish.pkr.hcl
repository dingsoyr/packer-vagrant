locals {
  version = formatdate("YYYY.MM.DD.hh", timestamp())
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
      box_tag       = "sture/${var.name}"
      version       = "${local.version}"
      architecture  = "amd64"
      box_checksum  = fileexists("builds/${var.name}_sha256.checksum") ? "SHA256:${split("\t", file("builds/${var.name}_sha256.checksum"))[0]}" : ""
    }
  }
}