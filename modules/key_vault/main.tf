/**
 * # Enterprise Azure Key Vault Module
 * 
 * Implements a hardened Key Vault adhering to Zero-Trust principles:
 * - Dynamic network_acls block for VNet & IP firewalls
 * - Map-based for_each secret injection
 * - Customer Managed Keys (CMK) generation for disk encryption
 * - Optional Private Endpoint integration with Private DNS Zone
 */

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                            = var.key_vault_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.sku_name
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  enable_rbac_authorization       = var.enable_rbac_authorization
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  public_network_access_enabled   = var.public_network_access_enabled
  tags                            = var.tags

  # ------------------------------------------------------------------------------------------------
  # Dynamic Network ACLs Block
  # ------------------------------------------------------------------------------------------------
  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Access Policies: for_each map iteration
# --------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "this" {
  for_each = var.access_policies

  key_vault_id            = azurerm_key_vault.this.id
  tenant_id               = each.value.tenant_id
  object_id               = each.value.object_id
  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
  storage_permissions     = each.value.storage_permissions
}

# --------------------------------------------------------------------------------------------------
# Secrets: Decoupled for_each using non-sensitive secret keys
# --------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "this" {
  for_each = toset(nonsensitive(keys(var.secrets)))

  name         = each.key
  value        = var.secrets[each.key].value
  key_vault_id = azurerm_key_vault.this.id
  content_type = var.secrets[each.key].content_type
  tags         = var.secrets[each.key].tags

  depends_on = [azurerm_key_vault_access_policy.this]
}

# --------------------------------------------------------------------------------------------------
# Cryptographic Keys (CMK / Disk Encryption): for_each iteration
# --------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_key" "this" {
  for_each = var.keys

  name         = each.key
  key_vault_id = azurerm_key_vault.this.id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  key_opts     = each.value.key_opts

  depends_on = [azurerm_key_vault_access_policy.this]
}

# --------------------------------------------------------------------------------------------------
# Private Endpoint (Zero-Trust Private Link Integration)
# --------------------------------------------------------------------------------------------------
resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint != null && try(var.private_endpoint.enabled, false) ? 1 : 0

  name                = "${var.key_vault_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "vault-dns-zone-group"
      private_dns_zone_ids = [var.private_endpoint.private_dns_zone_id]
    }
  }
}

