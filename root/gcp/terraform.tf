terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
  }
}

provider "google" {
  project = try(var.cloud_providers.gcp.project_id, null)
  region  = try(var.cloud_providers.gcp.region, "us-central1")

  user_project_override = true
}
