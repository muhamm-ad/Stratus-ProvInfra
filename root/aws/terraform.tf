terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
  }
}

provider "aws" {
  region     = try(var.cloud_providers.aws.region, "us-east-1")
  access_key = try(var.cloud_providers.aws.access_key, null)
  secret_key = try(var.cloud_providers.aws.secret_key, null)
  token      = try(var.cloud_providers.aws.access_token, null)

  default_tags {
    tags = merge(
      local.common_tags,
      {
        Provider = "AWS"
      }
    )
  }
}
