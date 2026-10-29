<div align="center">

# ☁️ Azure Enterprise Modular Infrastructure (IaC)
### Production-Grade Parent-Child Terraform Architecture with Zero-Trust Security

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure Provider](https://img.shields.io/badge/AzureRM-~%3E3.90-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![Security Standard](https://img.shields.io/badge/Security-NIST--800--53-00C853?style=for-the-badge&logo=shield&logoColor=white)](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
[![CI/CD Gate](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)](.github/workflows/terraform-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<p align="center">
  <strong>Architected & Maintained by <a href="https://github.com/anujsri192">Anuj Srivastava</a> — Lead DevSecOps Architect</strong>
</p>

</div>

---

## 📌 Executive Architecture Summary

This repository contains a battlefield-tested, enterprise-scale **Infrastructure as Code (IaC)** foundation for Microsoft Azure built with **HashiCorp Terraform**. It strictly adheres to the **Microsoft Cloud Adoption Framework (CAF)** and enterprise Zero-Trust principles.

### Key Architectural Highlights:
- **Child-Parent Module Hierarchy**: Clean abstraction separating reusable, modular components (`modules/*`) from target orchestration environments (`environments/prod`).
- **Advanced HCL2 Patterns**: Extensive utilization of `for_each` map-of-objects data structures and nested `dynamic` blocks for flexible, scalable infrastructure declaration.
- **Zero-Trust Azure Key Vault Integration**:
  - Hardened Key Vault deployment with automated Soft Delete (90-day retention) and Purge Protection.
  - Granular `dynamic "network_acls"` firewall whitelisting authorized subnets and administrative CIDRs.
  - Automated Customer Managed Key (**CMK**) provisioning (RSA 4096) for Azure Storage and Managed Disk encryption.
  - Automated secret bootstrapping (`random_password` and `tls_private_key`) securely stored in Key Vault with versionless URI references.
  - Zero-Trust **Private Endpoint** integration in dedicated subnets with private service connections.
- **Enterprise Networking**:
  - Modular Virtual Network supporting multi-tier subnetting via `for_each`.
  - Network Security Groups (NSGs) utilizing parameterized `dynamic "security_rule"` blocks with strict default-deny policies.
- **Elastic Compute Layer**:
  - Parameterized Linux Virtual Machines iterating over rich object maps.
  - Automated System-Assigned Managed Identity enablement for passwordless Azure service authentication.
  - Dynamic managed data disk attachment with automated LUN assignment and caching configurations.
- **Centralized Observability**:
  - Azure Log Analytics Workspace with automated diagnostic settings streaming Key Vault audit events and network telemetry.

---

## 🏛️ Repository File Hierarchy

```bash
azure-enterprise-terraform-modules/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml             # GitHub Actions CI/CD (fmt, validate, Trivy, Checkov)
├── modules/
│   ├── resource_group/                  # Core Azure Resource Group child module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── networking/                      # VNet, for_each subnets, dynamic NSG rules
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── key_vault/                       # Hardened Key Vault, dynamic ACLs, secrets, CMK, PE
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/                         # Linux VMs, dynamic identity, managed data disks
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/                      # Log Analytics Workspace, diagnostic settings
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   └── prod/                            # Production Parent / Orchestration Module
│       ├── main.tf                      # Module caller & inter-dependency wiring
│       ├── variables.tf                 # Strict type definitions & validation blocks
│       ├── terraform.tfvars             # Production environment parameter values
│       ├── outputs.tf                   # Structured exports & sensitive outputs
│       ├── versions.tf                  # Provider versions & backend constraints
│       └── provider.tf                  # AzureRM feature flags & provider hooks
├── .gitignore                           # Production Terraform gitignore
├── LICENSE                              # MIT License
└── README.md                            # Comprehensive enterprise documentation
```

---

## 🚀 Advanced Terraform Code Patterns

### 1. Dynamic Security Rules in NSG (`modules/networking/main.tf`)
Eliminates repetitive HCL declarations by transforming list maps into evaluated `security_rule` blocks:

```hcl
resource "azurerm_network_security_group" "this" {
  for_each            = var.network_security_groups
  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      description                = security_rule.value.description
    }
  }
}
```

### 2. Dynamic Network ACLs in Azure Key Vault (`modules/key_vault/main.tf`)
Enforces strict perimeter isolation while permitting Azure trusted services and whitelisted administrative IPs:

```hcl
resource "azurerm_key_vault" "this" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

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
```

### 3. Key Vault Secret Population with `for_each` Map
```hcl
resource "azurerm_key_vault_secret" "this" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value.value
  key_vault_id = azurerm_key_vault.this.id
  content_type = each.value.content_type
  tags         = each.value.tags

  depends_on   = [azurerm_key_vault_access_policy.this]
}
```

---

## 🛠️ Step-by-Step Deployment Runbook

### Prerequisites
1. **Terraform CLI**: Version `>= 1.5.0` installed.
2. **Azure CLI**: Logged in to your target subscription:
   ```bash
   az login
   az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
   ```

### Execution Steps

```bash
# Navigate to the production orchestration directory
cd environments/prod

# 1. Initialize Terraform plugins and child modules
terraform init

# 2. Format and validate syntax
terraform fmt -check -recursive
terraform validate

# 3. Generate and inspect an execution plan
terraform plan -out=tfplan.binary

# 4. Apply changes to Azure
terraform apply tfplan.binary
```

---

## 🔐 Zero-Trust Security & DevSecOps Compliance

- **No Plaintext Credentials**: All VM credentials, SSH private keys, and administrative secrets are generated in memory and dispatched straight to Azure Key Vault.
- **Continuous Security Auditing**: Every pull request triggers GitHub Actions running **Checkov** (CIS Azure Benchmark) and **Aqua Security Trivy**.
- **Automated Logging**: 100% of Key Vault management plane operations stream to Azure Log Analytics Workspaces.

---

## 👨‍💻 Author & Contributions

**Anuj Srivastava**
- **Role**: Lead DevSecOps Architect & Enterprise Cloud Systems Engineer
- **LinkedIn**: [Anuj Srivastava](https://www.linkedin.com/in/anujsri192)
- **GitHub**: [@anujsri192](https://github.com/anujsri192)
- **Email**: anujsri192@gmail.com

