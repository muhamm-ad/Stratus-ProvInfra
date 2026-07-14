<div align="center">

# Stratus-ProvInfra

**Infrastructure provisioning companion for [Stratus Gateway](https://github.com/muhamm-ad/stratus)**

Provision X Linux + Y Windows VMs (4 per provider) across AWS, Azure, and GCP with production-grade Terraform.
Features modular, reusable infrastructure code with DRY principles, environment layering, and
unified inventory integration.

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-blue)](https://www.terraform.io)
[![Status](https://img.shields.io/badge/status-production--ready-brightgreen)](#quick-start)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-compatible-purple)](https://opentofu.org)

</div>

---

## Overview

**Stratus-ProvInfra** is a multi-cloud infrastructure-as-code project that deploys and manages
test VMs across AWS, Azure, and GCP. It's designed as the infrastructure foundation for
[Stratus Gateway](https://github.com/muhamm-ad/stratus)—a desktop application that provides
single sign-on, unified VM inventory, and one-click connectivity across cloud providers.

### What's Included

- **VMs**: X Linux + Y Windows per cloud provider (AWS, Azure, GCP) Setup by the count variables.
- **Modular Terraform**: Shared modules for naming, tagging, and security
- **DRY principles**: Single-source-of-truth for naming conventions and tags
- **Environment layering**: dev/prod configurations with cost-aware sizing
- **Production-ready**: Validation, encryption, monitoring, and tagging built-in

### Key Features

- **Multi-cloud**: AWS EC2, Azure VMs, GCP Compute Instances
- **Modular design**: Reusable modules across all providers
- **Environment-aware**: Separate configs for dev, prod
- **RBAC-ready**: Tags enable Stratus access control
- **Cost-tracked**: Unified tagging for billing and chargeback
- **State management**: Remote backends with locking per environment

---

## Quick Start

### Prerequisites

- **Terraform** 1.5+ or **OpenTofu** 1.5+
- **Credentials**: AWS, Azure, and GCP authentication configured

### 5-Minute Setup

```bash
# 1. Clone
git clone https://github.com/muhamm-ad/stratus-provinfra.git
cd stratus-provinfra

# 2. Generate SSH key (for AWS Linux VMs)
./scripts/generate-ssh-key.sh

# 3. Initialize (from root module directory)
cd root
terraform init -backend-config=backend-dev.hcl

# 4. Plan
terraform plan -var-file=../env/dev.tfvars -out=tfplan

# 5. Apply
terraform apply tfplan

# 6. Export inventory
terraform output -json inventory > ../stratus-inventory.json
```

For detailed setup, see [docs/QUICK_START.md](docs/QUICK_START.md).

---

## VM Inventory

All VMs are exported in json format:

```json
{
  "aws": {
    "total_vms": 4,
    "vms": [
      {
        "id": "i-0123456789abc",
        "name": "dev_stratus_linux_1",
        "provider": "aws",
        "os": "linux",
        "ip": "203.0.113.1",
        "region": "us-east-1",
        "state": "running"
      }
    ]
  },
  "azure": { },
  "gcp": { }
}
```

---

## Cost Estimation

| Environment | Instance Types | Monthly Cost |
|-------------|----------------|--------------|
| **dev** | t3.micro, Standard_B1s, e2-micro | ~$5-10 |
| **prod** | t3.large, Standard_D2s_v3, n1-standard-2 | ~$150-250 |

---

## Usage Examples

### Deploy Only AWS

```bash
cd root
terraform plan -var-file=../env/dev.tfvars -var="enable_azure=false" -var="enable_gcp=false"
```

### Deploy Only Linux VMs

```bash
terraform plan -var-file=../env/dev.tfvars -var="windows_vm_count=0"
```

### Scale to 5 Linux VMs per Provider

```bash
terraform plan -var-file=../env/dev.tfvars -var="linux_vm_count=5"
```

### Add Custom Tags

```bash
terraform apply -var-file=../env/dev.tfvars -var='additional_tags={"Team":"Platform","CostCenter":"100"}'
```

---

## Security

### Best Practices

- SSH keys managed locally (not in repo)
- Windows passwords via environment variables (not in tfvars)
- State files encrypted at rest (S3, Azure Blob, GCS)
- All VMs tagged for RBAC filtering
- Security groups restrict SSH (22) and RDP (3389) to authorized sources

### Sensitive Data

All sensitive outputs (passwords, keys) are marked `sensitive = true` in Terraform.
State files are encrypted by default in remote backends.

---

## Related Projects

- **[Stratus Gateway](https://github.com/muhamm-ad/stratus)** — Desktop application for multi-cloud VM connectivity
- **[Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)** — AWS infrastructure provisioning
- **[Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)** — Azure infrastructure provisioning
- **[Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)** — GCP infrastructure provisioning
