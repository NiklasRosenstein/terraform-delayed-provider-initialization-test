terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
    minio = {
      source = "refaktory/minio"
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
  endpoint   = vultr_object_storage.main.s3_hostname
  ssl        = true
  access_key = vultr_object_storage.main.s3_access_key
  secret_key = vultr_object_storage.main.s3_secret_key
}

resource "minio_bucket" "test" {
  depends_on = [vultr_object_storage.main]
  name       = "test-bucket"
}
