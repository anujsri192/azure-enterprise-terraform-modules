environment  = "prod"
location     = "eastus"
project_name = "enterprise-core"

vnet_address_space = ["10.100.0.0/16"]

# Subnet Definitions (Map of objects)
subnets = {
  "snet-workloads" = {
    address_prefixes                          = ["10.100.1.0/24"]
    service_endpoints                         = ["Microsoft.KeyVault", "Microsoft.Storage"]
    private_endpoint_network_policies_enabled = true
    nsg_key                                   = "nsg-workloads"
  }
  "snet-private-endpoints" = {
    address_prefixes                          = ["10.100.2.0/24"]
    service_endpoints                         = []
    private_endpoint_network_policies_enabled = true
    nsg_key                                   = "nsg-private-endpoints"
  }
  "snet-management" = {
    address_prefixes                          = ["10.100.3.0/24"]
    service_endpoints                         = ["Microsoft.KeyVault"]
    private_endpoint_network_policies_enabled = true
    nsg_key                                   = "nsg-management"
  }
}

# Network Security Groups with dynamic security rules
network_security_groups = {
  "nsg-workloads" = {
    name = "nsg-enterprise-core-prod-workloads"
    security_rules = [
      {
        name                       = "allow-internal-vnet-https"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
        description                = "Allow intra-VNet TLS traffic"
      },
      {
        name                       = "allow-internal-ssh"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "22"
        source_address_prefix      = "10.100.3.0/24" # Management subnet only
        destination_address_prefix = "VirtualNetwork"
        description                = "Allow SSH exclusively from Management Subnet"
      },
      {
        name                       = "deny-all-inbound-internet"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        destination_port_range     = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Strict Zero-Trust: Deny all direct ingress from public internet"
      }
    ]
  }
  "nsg-private-endpoints" = {
    name = "nsg-enterprise-core-prod-pe"
    security_rules = [
      {
        name                       = "allow-vnet-inbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "443"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
        description                = "Allow private link ingress from spoke workloads"
      },
      {
        name                       = "deny-all-internet"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        destination_port_range     = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Deny public internet ingress to private endpoints"
      }
    ]
  }
  "nsg-management" = {
    name = "nsg-enterprise-core-prod-mgmt"
    security_rules = [
      {
        name                       = "allow-admin-ssh-gateway"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "22"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
        description                = "Allow SSH from corporate jumpbox"
      }
    ]
  }
}

allowed_admin_ip_ranges = []

common_tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
  CostCenter  = "CC-FINOPS-1042"
  Owner       = "Anuj Srivastava"
  Compliance  = "NIST-800-53"
  Project     = "Enterprise Cloud Modernization"
}

