
terraform {
  backend "gcs" {
    bucket = "storage-bucket-docker-223411-stage"
    prefix = "stage"
  }
}
