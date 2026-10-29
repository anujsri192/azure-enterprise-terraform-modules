/**
 * # Azure Resource Group Module
 * 
 * Standardized module for provisioning Azure Resource Groups with comprehensive enterprise tagging.
 */

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

