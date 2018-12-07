# Provider google

provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "gitlab-ci" {
  source           = "../modules/gitlab-ci"
  public_key_path  = "${var.public_key_path}"
  zone             = "${var.zone}"
  disk_image    = "${var.disk_image}"
  private_key_path = "${var.private_key_path}"
  provision_var    = "${var.provision_var}"
}

