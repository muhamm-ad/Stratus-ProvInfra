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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
  }
}

# AWS Provider (uses safe defaults when aws block is omitted)
provider "aws" {
  region     = try(var.cloud_providers.aws.region, "us-east-1")
  access_key = try(var.cloud_providers.aws.access_key, "")
  secret_key = try(var.cloud_providers.aws.secret_key, "")
  token      = try(var.cloud_providers.aws.access_token, "")

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

# Google Provider (uses safe defaults when gcp block is omitted)
provider "google" {
  project = try(var.cloud_providers.gcp.project_id, "")
  region  = try(var.cloud_providers.gcp.region, "us-central1")

  user_project_override = true
}

# Random provider (for generating unique suffixes)
provider "random" {}
