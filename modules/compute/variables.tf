variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The Azure region for the VMs."
  type        = string
}

variable "virtual_machines" {
  description = <<EOF
Map of Linux Virtual Machines to provision.
Key is the machine identifier.
Value contains:
- name: string
- vm_size: string
- admin_username: string
- admin_ssh_public_key: optional SSH public key string (can be pulled from Key Vault or generated)
- admin_password: optional admin password (stored in Key Vault)
- disable_password_authentication: bool (defaults to true)
- subnet_id: ID of the subnet where the NIC will reside
- private_ip_address_allocation: "Dynamic" or "Static"
- private_ip_address: optional static IP
- os_disk_type: "Standard_LRS", "Premium_LRS", etc.
- os_disk_size_gb: number
- source_image_reference: object with publisher, offer, sku, version
- identity_type: optional "SystemAssigned" or "UserAssigned"
- identity_ids: optional list of User Assigned Identity IDs
- data_disks: optional map of data disks (size_gb, disk_type, caching, lun)
EOF
  type = map(object({
    name                            = string
    vm_size                         = string
    admin_username                  = string
    admin_ssh_public_key            = optional(string)
    admin_password                  = optional(string)
    disable_password_authentication = optional(bool, true)
    subnet_id                       = string
    private_ip_address_allocation   = optional(string, "Dynamic")
    private_ip_address              = optional(string)
    os_disk_type                    = optional(string, "Premium_LRS")
    os_disk_size_gb                 = optional(number, 64)
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
      }), {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"
    })
    identity_type = optional(string, "SystemAssigned")
    identity_ids  = optional(list(string), [])
    data_disks = optional(map(object({
      size_gb = number
      type    = optional(string, "Premium_LRS")
      caching = optional(string, "ReadWrite")
      lun     = number
    })), {})
  }))
}

variable "boot_diagnostics_enabled" {
  description = "Whether to enable managed boot diagnostics."
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_uri" {
  description = "Storage account URI for boot diagnostics (null for managed storage)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all compute resources."
  type        = map(string)
  default     = {}
}
