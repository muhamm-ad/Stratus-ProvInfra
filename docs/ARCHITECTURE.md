# Stratus-ProvInfra Architecture

## Design Principles

### 1. **Modularity**

- **Provider modules** (`modules/aws/*`, `modules/azure/*`, `modules/gcp/*`): Each provider is fully isolated. No cross-provider imports.
- **Root orchestration** (`root/`): Single point of composition; coordinates provider modules and applies unified variables.

### 2. **Maintainability**

- **Single Responsibility**: Each module owns one logical unit (VPC networking, VM compute, security groups).
- **Clear Contracts**: Every module has explicit `variables.tf`, `main.tf`, `outputs.tf`.
- **No Magic**: All naming, tagging, and defaults are explicit; no hidden computed values.
- **Versioning**: Pin provider versions in `terraform.tf`; use `~>` for patch-level flexibility.

### 3. **DRY (Don't Repeat Yourself)**

- **Shared tagging**: All resources inherit `local.common_tags` from `root/main.tf`.
- **Naming conventions**: Standardized format `{env}_{project}_{component}_{index}` enforced across modules.
- **Conditional composition**: Provider and OS enablement derived from structured input variables.

### 4. **Environment Layering**

- **Two environments**: `dev` (testing), `prod` (hardened).
- **Per-environment vars**: `env/dev.tfvars`, `env/prod.tfvars` override defaults.
- **Selective deployment**: Omit provider or OS blocks in tfvars to deploy only what you need.

## Configuration Variables

### `cloud_providers`

Structured object with optional `aws`, `azure`, and `gcp` blocks. At least one must be present.

```hcl
cloud_providers = {
  aws = {
    region       = "us-east-1"
    access_key   = string
    secret_key   = string
    access_token = string
    vpc_cidr     = string
  }
  azure = {
    resource_group_name = string
    location            = string
    vnet_cidr           = string
  }
  gcp = {
    project_id   = string
    region       = string
    network_cidr = string
  }
}
```

Root locals derive enable flags:

```hcl
enable_aws   = var.cloud_providers.aws != null
enable_azure = var.cloud_providers.azure != null
enable_gcp   = var.cloud_providers.gcp != null
```

### `instances`

Structured object with optional `linux` and `windows` blocks. Defaults to `{}` (no VMs).

```hcl
instances = {
  linux = {
    count = number
    instance_type = {
      aws   = string
      azure = string
      gcp   = string
    }
    cidr = {
      aws   = string
      azure = string
      gcp   = string
    }
  }
  windows = { /* same shape */ }
}
```

Root locals derive OS enable flags:

```hcl
enable_linux   = var.instances.linux != null
enable_windows = var.instances.windows != null
```

When an OS is omitted:

- No compute resources for that OS are created
- No subnet for that OS is created in network modules
- Inventory and outputs report `0` for that OS count

## Module Dependency Graph

```text
root/
├── [if cloud_providers.aws] → modules/aws/vpc/
│                              modules/aws/security/
│                              modules/aws/compute/  (per enabled OS)
│
├── [if cloud_providers.azure] → modules/azure/network/  (subnets per enabled OS)
│                                modules/azure/nsg/
│                                modules/azure/compute/  (per enabled OS)
│
└── [if cloud_providers.gcp] → modules/gcp/network/  (subnets per enabled OS)
                               modules/gcp/firewall/
                               modules/gcp/compute/  (per enabled OS)
```

## Root Module Orchestration

**`root/main.tf`**: Instantiates provider modules with conditional `count`:

```hcl
module "aws_vpc" {
  count  = local.enable_aws ? 1 : 0
  source = "../modules/aws/vpc"

  subnet_configs = merge(
    local.enable_linux ? { linux = { cidr = ..., az = ... } } : {},
    local.enable_windows ? { windows = { cidr = ..., az = ... } } : {}
  )
}

module "aws_compute" {
  count = local.enable_aws ? 1 : 0

  linux_instances   = local.enable_linux ? { ... } : null
  windows_instances = local.enable_windows ? { ... } : null
}
```

**Variable Flow**:

1. User provides `env/dev.tfvars`
2. `root/variables.tf` validates types and constraints
3. `root/main.tf` locals compute enable flags, naming prefix, and tags
4. `root/main.tf` passes conditional inputs to module instances
5. Each module creates only the resources for enabled workloads

**State Architecture**:

- **Single state file per environment** (dev, prod)
- Remote backends: S3 (AWS), Blob Storage (Azure), GCS (GCP)
- State locking prevents concurrent applies
- Sensitive data (passwords, keys) marked as `sensitive = true`

## Network Module Design

Network modules use `for_each` on `subnet_configs` so subnets are created only for enabled operating systems:

- **AWS** (`modules/aws/vpc`): `aws_subnet.workload` keyed by OS name
- **Azure** (`modules/azure/network`): `azurerm_subnet.workload` keyed by OS name
- **GCP** (`modules/gcp/network`): `google_compute_subnetwork.workload` keyed by OS name

`moved` blocks preserve state when upgrading from static `linux`/`windows` subnet resources.

Compute modules accept nullable `linux_instances` / `windows_instances` objects. When `null`, `count` resolves to `0` and no VMs, NICs, or image lookups are created.

## Naming Convention

All resources follow: `{environment}_{project_name}_{component}_{index}`

Examples:

- VPC: `dev_stratus_vpc`
- Subnets: `dev_stratus_subnet_linux`, `dev_stratus_subnet_windows`
- Linux VMs: `dev_stratus_linux_1`, `dev_stratus_linux_2`
- Windows VMs: `dev_stratus_windows_1`, `dev_stratus_windows_2`
- Security Group: `dev_stratus_sg`
- SSH Key: `dev_stratus_key`

**Rationale**: Globally unique within account/subscription/project; obvious from name which env and component; sortable by age (env prefix).

## Tagging Strategy

Every resource inherits:

```hcl
{
  Environment = var.environment
  Project     = var.project_name
  ManagedBy   = "terraform"
  CreatedAt   = <timestamp>
  ModifiedAt  = <timestamp>
  Owner       = var.owner_email
  [additional_tags]
}
```

**Audit**: By `Owner`, `CreatedAt`; filter by `ManagedBy="terraform"`.  
**RBAC**: Azure/GCP IAM roles keyed on `Owner`; Stratus Gateway inventory filters by owner email.

## VM Configuration

### Linux VMs (Ubuntu 24.04 LTS)

- Instance types: AWS t3.micro (dev), t3.large (prod)
- Image: Latest Ubuntu 24.04 LTS (updated monthly)
- SSH: Public key from `security.ssh.public_key_path`
- Storage: 30 GB root volume
- Network: Public IP on AWS (via IGW), private on Azure/GCP (NAT)

### Windows VMs (Windows Server 2022)

- Instance types: AWS t3.small, Azure Standard_B2s, GCP e2-small
- Image: Latest Windows Server 2022 (patched)
- RDP: Admin user (default: "azureuser"), password via `security.windows.password`
- Storage: 32 GB root volume
- Network: Private IP (Windows typically doesn't need direct internet in test scenarios)

## State Management

**Backend Configuration** (per environment):

```hcl
# backend-dev.hcl
bucket         = "stratus-provinfra-state-dev"
key            = "terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-lock"
encrypt        = true
```

**State Locks**: Prevent concurrent applies. Locks held in:

- AWS: DynamoDB table `terraform-lock`
- Azure: Blob Storage lease
- GCP: Cloud Storage object lock

**Sensitive Data in State**:

- Windows admin password (marked `sensitive = true`)
- SSH private key (never stored; user-managed)
- State file stored encrypted at rest

## Scaling Considerations

### Horizontal Scaling

- Increase `instances.linux.count` or `instances.windows.count` in tfvars
- Uses `count` in compute modules: `count.index` for unique naming, IP assignment
- Example: `instances.linux.count = 5` with three providers enabled → 15 Linux VMs total

### Provider-Specific Limits

- **AWS**: EC2 instance limit (default 10 on-demand), security group rules limit (120)
- **Azure**: VNets per subscription (50), VMs per region (100+)
- **GCP**: Compute instances per project (flexible; quotas by machine type)

### Cost Scaling

- `dev` sizing: ~$5-10/month (free tier eligible)
- `prod` sizing: ~$150-250/month
- Omit providers or OS blocks to reduce cost proportionally

## Inventory

**Inventory Export**:

```bash
terraform output -json inventory > inventory.json
```

**Inventory Format**:

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

Disabled providers return `null`. VM counts in `deployment_summary` use `try()` to report `0` for omitted OS blocks.

## Testing & Validation

**Linting** (`tflint`):

- Naming conventions (resource names match pattern)
- Unused variables/outputs
- Cloud-specific best practices (e.g., enable encryption, versioning)

**Validation** (`terraform validate`):

- Syntax correctness
- Required variable presence
- Type mismatches on structured objects

**Plan Review** (`terraform plan`):

- Resource addition/modification/deletion
- Variable interpolation correctness
- Dependency ordering

**Post-Deploy Verification**:

- SSH to Linux VMs; verify cloud-init logs
- RDP to Windows VMs; verify Windows Update
- Check security group rules (AWS/GCP) and NSG (Azure)
- Verify tags on all resources

## Security Best Practices

1. **Network Isolation**:
   - Linux subnets public, Windows private
   - NAT Gateway for outbound Windows traffic
   - Network ACLs on AWS for stateless filtering

2. **Access Control**:
   - SSH key-based auth (no passwords)
   - RDP admin password enforced (12+ chars, complexity)
   - Security groups restrict ports 22, 3389

3. **Encryption**:
   - State files encrypted at rest (S3, Blob, GCS)
   - SSH in transit (TLS/OpenSSH)
   - Windows passwords marked `sensitive` (Terraform logs redacted)

4. **Monitoring & Audit**:
   - CloudWatch detailed monitoring on EC2
   - VNet flow logs on Azure
   - Cloud Logging on GCP
   - All infrastructure changes tagged with date, owner

5. **Credential Management**:
   - SSH public key in repo (OK)
   - SSH private key in `~/.ssh` (user-managed, not in repo)
   - Windows password via env var or tfvars `security.windows.password` (never commit secrets)

## Troubleshooting Guide

**Common Issues**:

1. **"Error: invalid type for ..."** → Type mismatch in tfvars. Verify object keys match the schema in `root/variables.tf`.
2. **"Error: resource already exists"** → State mismatch. Use `terraform import` or `terraform destroy` + recreate.
3. **"Error: subnet CIDR conflicts"** → CIDR overlaps. Check `vpc_cidr`, `vnet_cidr`, `network_cidr` in `cloud_providers`.
4. **Windows admin password rejected** → Password doesn't meet Azure/GCP complexity (12+ chars, mixed case, numbers, symbols).
5. **SSH key not found** → Run `./scripts/generate-ssh-key.sh` and verify `security.ssh.public_key_path`.
6. **Unexpected resources created** → Check that omitted providers/OS blocks are removed from tfvars, not set to empty objects.

**Debug Steps**:

```bash
terraform refresh
terraform state list
terraform state show 'module.aws_compute[0].aws_instance.linux[0]'
terraform console
```
