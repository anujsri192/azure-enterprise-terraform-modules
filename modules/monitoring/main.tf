/**
 * # Enterprise Monitoring & Observability Module
 * 
 * Provisions an Azure Log Analytics Workspace with centralized diagnostic settings:
 * - Dynamic enabled_log blocks for multi-category telemetry
 * - Dynamic metric blocks for metric ingestion
 */

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

# --------------------------------------------------------------------------------------------------
# Diagnostic Settings: for_each iteration over resources with dynamic log/metric blocks
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                       = "${each.key}-diag"
  target_resource_id         = each.value.target_resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}

