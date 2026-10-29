terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Production remote backend configuration (configured via backend-config or pipeline)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-tfstate"
  #   storage_account_name = "stentertfstateprod"
  #   container_name       = "tfstate"
  #   key                  = "prod.terraform.tfstate"
  # }
}

