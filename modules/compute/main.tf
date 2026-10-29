/**
 * # Enterprise Compute Module (Linux Virtual Machines)
 * 
 * Provisions enterprise Linux Virtual Machines using:
 * - for_each map iteration for multi-VM scaling
 * - Dynamic identity blocks (SystemAssigned / UserAssigned)
 * - Dynamic admin_ssh_key blocks
 * - Dynamic boot_diagnostics
 * - Dynamic managed data disk attachment map flattening
 */

# --------------------------------------------------------------------------------------------------
# Network Interfaces: One per Virtual Machine
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "this" {
  for_each = var.virtual_machines

  name                = "${each.value.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = each.value.private_ip_address_allocation
    private_ip_address            = each.value.private_ip_address
  }
}

# --------------------------------------------------------------------------------------------------
# Linux Virtual Machines: Iterating over map of VM definitions
# --------------------------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "this" {
  for_each = var.virtual_machines

  name                            = each.value.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = each.value.vm_size
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password
  disable_password_authentication = each.value.disable_password_authentication
  network_interface_ids           = [azurerm_network_interface.this[each.key].id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  # Dynamic SSH Key Block
  dynamic "admin_ssh_key" {
    for_each = each.value.admin_ssh_public_key != null ? [1] : []
    content {
      username   = each.value.admin_username
      public_key = each.value.admin_ssh_public_key
    }
  }

  # Dynamic Managed Identity Block
  dynamic "identity" {
    for_each = each.value.identity_type != null ? [1] : []
    content {
      type         = each.value.identity_type
      identity_ids = each.value.identity_ids
    }
  }

  # Dynamic Boot Diagnostics Block
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_enabled ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_uri
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Managed Data Disks: Flattened iteration for dynamic disk provisioning & attachment
# --------------------------------------------------------------------------------------------------
locals {
  data_disks_flattened = merge([
    for vm_key, vm in var.virtual_machines : {
      for disk_key, disk in vm.data_disks : "${vm_key}-${disk_key}" => {
        vm_key  = vm_key
        name    = "${vm.name}-${disk_key}"
        size_gb = disk.size_gb
        type    = disk.type
        caching = disk.caching
        lun     = disk.lun
      }
    }
  ]...)
}

resource "azurerm_managed_disk" "this" {
  for_each = local.data_disks_flattened

  name                 = each.value.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.type
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = local.data_disks_flattened

  managed_disk_id    = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.this[each.value.vm_key].id
  lun                = each.value.lun
  caching            = each.value.caching
}

