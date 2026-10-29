variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region for monitoring resources."
  type        = string
}

variable "workspace_name" {
  description = "The name of the Log Analytics Workspace."
  type        = string
}

variable "sku" {
  description = "The SKU of the Log Analytics Workspace."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Workspace data retention in days (between 30 and 730)."
  type        = number
  default     = 30
}

variable "diagnostic_settings" {
  description = <<EOF
Map of diagnostic settings to attach to resources.
Key is a unique descriptive name.
Value contains:
- target_resource_id: resource to stream logs/metrics from
- log_categories: list of log categories to enable
- metric_categories: list of metric categories to enable
EOF
  type = map(object({
    target_resource_id = string
    log_categories     = optional(list(string), [])
    metric_categories  = optional(list(string), ["AllMetrics"])
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to all monitoring resources."
  type        = map(string)
  default     = {}
}

