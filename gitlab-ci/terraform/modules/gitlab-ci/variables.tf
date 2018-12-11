variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable disk_image {
  description = "Disk image for reddit db"
  default     = "gitlab-ci"
}

variable "private_key_path" {
  description = "Path to the private key used for ssh access"
}

variable provision_var {
  description = "Set this var to 1 for provision runnig"
}

variable count {
  description = "Count"
  default     = "1"
}

