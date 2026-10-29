variable "name" {
  description = "The name of the resource group. Must conform to enterprise naming standards."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.name))
    error_message = "Resource group name must be between 3 and 63 lowercase alphanumeric characters or hyphens."
  }
}

variable "location" {
  description = "The Azure region where the resource group should be created."
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

