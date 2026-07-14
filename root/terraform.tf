terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend configured per-environment via backend config files or CLI flags
  # Example: terraform init -backend-config=backend-dev.hcl
  # backend "s3" {} — for AWS
  # backend "azurerm" {} — for Azure
  # backend "gcs" {} — for GCP
}

# AWS Provider
provider "aws" {
  region     = var.providers.aws.region
  access_key = var.providers.aws.access_key
  secret_key = var.providers.aws.secret_key
  token      = var.providers.aws.access_token

  default_tags {
    tags = merge(
      local.common_tags,
      {
        Provider = "AWS"
      }
    )
  }
}

# Azure Provider
provider "azurerm" {
  features {}

  skip_provider_registration = false
}

# Google Provider
provider "google" {
  project = var.providers.gcp.project_id
  region  = var.providers.gcp.region

  user_project_override = true
}

# Random provider (for generating unique suffixes)
provider "random" {}
