terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }

  # GCS backend so state survives across GitHub Actions runs (CI has no
  # persistent local disk between jobs). Bucket is created once by
  # bootstrap/bootstrap.sh; its name is supplied at init time
  # (`terraform init -backend-config=...`), not hardcoded here, since a
  # backend block can't reference a variable.
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
