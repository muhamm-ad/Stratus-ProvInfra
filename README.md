<div align="center">

# Stratus-ProvInfra

**Infrastructure provisioning companion for [Stratus Gateway](https://github.com/muhamm-ad/stratus)**

Provision Linux and/or Windows VMs across AWS, Azure, and GCP with production-grade Terraform.
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

- **VMs**: Optional Linux and/or Windows workloads per enabled cloud provider
- **Modular Terraform**: Provider-specific modules for networking, security, and compute
- **DRY principles**: Single-source-of-truth for naming conventions and tags
- **Environment layering**: dev/prod configurations with cost-aware sizing
- **Production-ready**: Validation, encryption, monitoring, and tagging built-in

### Key Features

- **Multi-cloud**: AWS EC2, Azure VMs, GCP Compute Instances
- **Selective deployment**: Enable only the providers and operating systems you need
- **Modular design**: Reusable modules across all providers
- **Environment-aware**: Separate configs for dev and prod
- **RBAC-ready**: Tags enable Stratus access control
- **Cost-tracked**: Unified tagging for billing and chargeback
- **State management**: Local state per environment via Terraform workspaces (dev, prod)

---

## Configuration Model

Deployment scope is controlled in `env/*.tfvars` via two structured variables:

| Variable | Purpose |
|----------|---------|
| `cloud_providers` | Which clouds to deploy (`aws`, `azure`, `gcp`). At least one block is required. |
| `instances` | Which operating systems to deploy (`linux`, `windows`). Defaults to `{}` (no VMs). |

Omit a provider or OS block entirely to skip provisioning it. When a block is present, all nested fields are required.

```hcl
# AWS only, Linux only
cloud_providers = {
  aws = {
    region       = "us-east-1"
    access_key   = ""
    secret_key   = ""
    access_token = ""
    vpc_cidr     = "10.0.0.0/16"
  }
}

instances = {
  linux = {
    count = 2
    instance_type = {
      aws   = "t3.micro"
      azure = "Standard_B1s"
      gcp   = "e2-micro"
    }
    cidr = {
      aws   = "10.0.1.0/24"
      azure = "10.1.1.0/24"
      gcp   = "10.2.1.0/24"
    }
  }
}
```

See `env/dev.tfvars.exemple` for a full multi-cloud example.

---

## Quick Start

### Prerequisites

- **Terraform** 1.5+ or **OpenTofu** 1.5+
- **Credentials**: AWS, Azure, and/or GCP authentication configured for the providers you enable

### 5-Minute Setup

```bash
# 1. Clone
git clone https://github.com/muhamm-ad/stratus-provinfra.git
cd stratus-provinfra

# 2. Generate SSH key (for Linux VMs)
./scripts/generate-ssh-key.sh

# 3. Copy and edit environment config
cp env/dev.tfvars.exemple env/dev.tfvars
# Edit cloud_providers and instances to match your target deployment

# 4. Initialize workspace and deploy
./scripts/init.sh dev
./scripts/deploy.sh dev

# Or manually from root/:
cd root
terraform init
terraform workspace select dev   # or: terraform workspace new dev
terraform plan -var-file=../env/dev.tfvars -out=tfplan
terraform apply tfplan

# 5. Export inventory
terraform output -json inventory > ../stratus-inventory.json
```

For detailed setup, see [docs/QUICK_START.md](docs/QUICK_START.md).

---

## VM Inventory

All VMs are exported in JSON format:

```json
{
  "aws": {
    "total_vms": 2,
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
  "azure": null,
  "gcp": null
}
```

Disabled providers return `null` in the inventory output.

---

## Cost Estimation

| Environment | Instance Types | Monthly Cost |
|-------------|----------------|--------------|
| **dev** | t3.micro, Standard_B1s, e2-micro | ~$5-10 |
| **prod** | t3.large, Standard_D2s_v3, n1-standard-2 | ~$150-250 |

Costs scale with the number of enabled providers and OS workloads.

---

## Usage Examples

### Deploy Only AWS

Remove `azure` and `gcp` from `cloud_providers` in your tfvars:

```hcl
cloud_providers = {
  aws = {
    region       = "us-east-1"
    access_key   = ""
    secret_key   = ""
    access_token = ""
    vpc_cidr     = "10.0.0.0/16"
  }
}
```

### Deploy Only Linux VMs

Omit the `windows` block from `instances`:

```hcl
instances = {
  linux = {
    count = 1
    instance_type = { aws = "t3.micro", azure = "Standard_B1s", gcp = "e2-micro" }
    cidr          = { aws = "10.0.1.0/24", azure = "10.1.1.0/24", gcp = "10.2.1.0/24" }
  }
}
```

### Scale Linux VMs

Increase `instances.linux.count` in your tfvars:

```hcl
instances = {
  linux = {
    count = 5
    # ...
  }
}
```

With three providers enabled, `count = 5` creates 5 Linux VMs per provider (15 total).

### Deploy Networking Only (No VMs)

```hcl
instances = {}
```

Provider networking (VPC, VNet, firewall rules) is still created for enabled `cloud_providers`.

### Add Custom Tags

```bash
terraform apply -var-file=../env/dev.tfvars \
  -var='additional_tags={"Team":"Platform","CostCenter":"100"}'
```

---

## Security

### Best Practices

- SSH keys managed locally (not in repo)
- Windows passwords via environment variables (not in tfvars)
- State files stored locally per workspace (gitignored; not committed)
- All VMs tagged for RBAC filtering
- Security groups restrict SSH (22) and RDP (3389) to authorized sources

### Sensitive Data

All sensitive outputs (passwords, keys) are marked `sensitive = true` in Terraform.
State files live under `root/.terraform/` and are excluded from version control.

---

## Related Projects

- **[Stratus Gateway](https://github.com/muhamm-ad/stratus)** — Desktop application for multi-cloud VM connectivity
- **[Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)** — AWS infrastructure provisioning
- **[Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)** — Azure infrastructure provisioning
- **[Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)** — GCP infrastructure provisioning
