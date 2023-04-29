terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
    minio = {
      source = "aminueza/minio"
    }
  }
}


data "vultr_object_storage_cluster" "ams" {
  filter {
    name   = "region"
    values = ["ams"]
  }
}

resource "vultr_object_storage" "main" {
  cluster_id = data.vultr_object_storage_cluster.ams.id
  label      = "test-storage"
}

provider "minio" {
  minio_server   = vultr_object_storage.main.s3_hostname
  minio_user     = vultr_object_storage.main.s3_access_key
  minio_password = vultr_object_storage.main.s3_secret_key
}

resource "minio_s3_bucket" "test" {
  depends_on = [vultr_object_storage.main]
  bucket     = "test-bucket"
}
