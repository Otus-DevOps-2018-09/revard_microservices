resource "google_compute_instance" "gitlab-ci" {
  name         = "gitlab-ci"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"
  tags         = ["gitlab-ci" , "docker-host" , "http-server" , "https-server"]
  count        = "${var.count}"

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  network_interface {
    network = "default"

    access_config = {}
  }

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "null_resource" "docker_provisioner" {
  count = "${var.provision_var}"

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
    host        = "${google_compute_instance.gitlab-ci.network_interface.0.access_config.0.nat_ip}"
  }

}

