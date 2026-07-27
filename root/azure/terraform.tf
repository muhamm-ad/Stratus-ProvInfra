terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = try(var.cloud_providers.azure.subscription_id, "")
  client_id       = try(var.cloud_providers.azure.client_id, "")
  client_secret   = try(var.cloud_providers.azure.client_secret, "")
  tenant_id       = try(var.cloud_providers.azure.tenant_id, "")

  skip_provider_registration = true

}
