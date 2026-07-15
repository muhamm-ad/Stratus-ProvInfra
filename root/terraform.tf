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
  access_key = local.enable_aws ? try(var.cloud_providers.aws.access_key, null) : null
  secret_key = local.enable_aws ? try(var.cloud_providers.aws.secret_key, null) : null
  token      = local.enable_aws ? try(var.cloud_providers.aws.access_token, null) : null

  # Skip the STS GetCallerIdentity check when AWS isn't in use so Configure
  # doesn't require real credentials for a provider nothing will call.
  skip_credentials_validation = !local.enable_aws
  skip_requesting_account_id  = !local.enable_aws

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
# NOTE: unlike aws/google, azurerm has no "skip auth" flag - it always makes a
# real call to Azure AD (or the Azure CLI) during Configure, even when
# local.enable_azure is false and no azurerm resource exists in the plan.
# A logged-in `az` session (or real ARM_* credentials) is required to plan/apply
# at all while this provider block is unconditionally declared in this root.
provider "azurerm" {
  features {}

  skip_provider_registration = false
}

# Google Provider (uses safe defaults when gcp block is omitted)
provider "google" {
  # google requires project to be either a real value or entirely unset -
  # an empty string fails Configure, so fall back to null, not "".
  project = try(var.cloud_providers.gcp.project_id, null)
  region  = try(var.cloud_providers.gcp.region, "us-central1")

  # When GCP isn't in use, a bogus access_token stops the provider from
  # searching for Application Default Credentials during Configure.
  access_token = local.enable_gcp ? null : "unused"

  user_project_override = true
}

# Random provider (for generating unique suffixes)
provider "random" {}
