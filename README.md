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
- **AWS user data**: Cloud-init (Linux) and PowerShell (Windows) first-boot templates

### Key Features

- **Multi-cloud**: AWS EC2, Azure VMs, GCP Compute Instances
- **Selective deployment**: Enable only the providers and operating systems you need
- **Modular design**: Reusable modules across all providers
- **Environment-aware**: Separate configs for dev and prod
- **RBAC-ready**: Tags enable Stratus access control
- **Cost-tracked**: Unified tagging for billing and chargeback
- **State management**: Local state per cloud, per environment via Terraform workspaces (dev, prod)

---

## Configuration Model

Each cloud has its own independent root config — `root/aws/`, `root/azure/`, `root/gcp/` —
each with its own provider, state, and Terraform workspaces. **Which cloud gets deployed
is chosen by which root you run** (`./scripts/deploy.sh aws|azure|gcp ...`), not by which
keys you populate in tfvars. This is a hard Terraform constraint, not a style choice:
providers are configured for every declared `provider` block regardless of resource
usage, so the only way to make a cloud provider truly optional is to keep it out of the
root entirely when you're not using it. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
for the full rationale.

All three roots read the **same** `env/*.tfvars` file, structured via two variables:

| Variable | Purpose |
|----------|---------|
| `cloud_providers` | Connection details for `aws`, `azure`, `gcp`. Each root only reads its own slice, but you can fill in all three in one file. |
| `instances` | Which operating systems to deploy (`linux`, `windows`), within whichever cloud you're running. Defaults to `{}` (no VMs). |

Each root requires its own `cloud_providers.<cloud>` slice to be present (validated at
`terraform validate` time). Omit an OS block entirely to skip provisioning it; when a
block is present, all nested fields are required.

VM admin usernames are derived from the local-part of `owner_email` (e.g.
`alice@example.com` → `alice`). There is no separate `security` block in tfvars.

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

# 2. Copy and edit environment config
cp env/dev.tfvars.exemple env/dev.tfvars
# Edit cloud_providers and instances to match your target deployment(s)

# 3. Initialize workspace and deploy - pick a cloud: aws, azure, or gcp
./scripts/init.sh aws dev
./scripts/deploy.sh aws dev

# Or manually from root/<cloud>:
cd root/aws
terraform init
terraform workspace select dev   # or: terraform workspace new dev
terraform plan -var-file=../../env/dev.tfvars -out=tfplan
terraform apply tfplan

# 4. Export inventory (deploy.sh does this automatically)
terraform output -json inventory > ../../stratus-inventory-aws.json

# To deploy to more than one cloud, repeat steps 3-4 for azure and/or gcp -
# each cloud is a fully independent apply with its own state.
```

For detailed setup, see [docs/QUICK_START.md](docs/QUICK_START.md).

---

## VM Inventory

Each cloud's `inventory` output is exported in JSON format, one file per cloud
(`deploy.sh <cloud>` does this automatically after apply).

**AWS** inventory includes separate IP and DNS fields:

```json
{
  "total_vms": 2,
  "vms": [
    {
      "id": "i-0123456789abc",
      "name": "dev_stratus_linux_1",
      "provider": "aws",
      "os": "linux",
      "type": "t3.micro",
      "private_ip": "10.0.1.10",
      "public_ip": "203.0.113.1",
      "public_dns": "ec2-203-0-113-1.compute-1.amazonaws.com",
      "region": "us-east-1",
      "state": "running"
    }
  ]
}
```

**Azure** and **GCP** inventory use a single `ip` field (private on Azure; Linux
prefers external IP on GCP, Windows uses internal).

To combine inventories from multiple clouds into one file, merge
`stratus-inventory-aws.json`, `stratus-inventory-azure.json`, and
`stratus-inventory-gcp.json` yourself (e.g. with `jq -n`) — a single apply only
ever has one cloud's data.

---

## Cost Estimation

| Environment | Instance Types | Monthly Cost (per cloud) |
|-------------|----------------|--------------|
| **dev** | t3.micro, Standard_B1s, e2-micro | ~$5-10 |
| **prod** | t3.large, Standard_D2s_v3, n1-standard-2 | ~$150-250 |

Costs scale with the number of clouds you deploy to and the OS workloads enabled on each.

---

## Usage Examples

### Deploy Only AWS

Just run the AWS root — the other clouds' roots simply aren't invoked, so their
providers are never configured or authenticated to:

```bash
./scripts/deploy.sh aws dev
```

Your `cloud_providers.azure`/`.gcp` blocks (if present in the shared tfvars) are
ignored by this run; they only matter if you separately run `deploy.sh azure` or
`deploy.sh gcp`.

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

Deployed via `deploy.sh aws`, `deploy.sh azure`, and `deploy.sh gcp`, `count = 5`
creates 5 Linux VMs per cloud you actually ran (15 total across all three).

### Deploy Networking Only (No VMs)

```hcl
instances = {}
```

Networking (VPC, VNet, firewall rules) is still created for whichever cloud's root
you run.

### Add Custom Tags

```bash
# from root/<cloud>
terraform apply -var-file=../../env/dev.tfvars \
  -var='additional_tags={"Team":"Platform","CostCenter":"100"}'
```

---

## Security

### Best Practices

- State files stored locally per cloud, per workspace (gitignored; not committed)
- All VMs tagged for RBAC filtering (`Owner` from `owner_email`)
- Security groups / NSGs allow SSH (22) and RDP (3389); tighten CIDRs for production
- AWS Windows user data creates a short-lived local admin (account expires ~10 minutes
  after first boot) and installs OpenSSH Server
- Do not commit secrets in tfvars — keep `env/*.tfvars` untracked

### Sensitive Data

State files live under `root/<cloud>/terraform.tfstate.d/<workspace>/` and are
excluded from version control. Initial Windows passwords appear in user data / state on AWS — treat state as sensitive.

---

## Related Projects

- **[Stratus Gateway](https://github.com/muhamm-ad/stratus)** — Desktop application for multi-cloud VM connectivity
- **[Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)** — AWS infrastructure provisioning
- **[Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)** — Azure infrastructure provisioning
- **[Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)** — GCP infrastructure provisioning
