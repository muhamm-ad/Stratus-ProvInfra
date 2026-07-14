# Stratus-Terraform Architecture

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

- **Shared tagging**: All resources inherit `local.common_tags` from `root/locals.tf`.
- **Naming conventions**: Standardized format `{env}_{project}_{component}_{index}` enforced in `modules/shared/naming/`.
- **Security rules**: SSH/RDP rules defined once in `modules/shared/security_group_rules/`, used by all providers.

### 4. **Environment Layering**

- **Two environments**: `dev` (testing), `prod` (hardened).
- **Per-environment vars**: `env/dev.tfvars`, `env/prod.tfvars` override defaults.
- **Enable/disable per-provider**: Set `enable_aws=true/false` to deploy only to desired clouds.

## Module Dependency Graph

```text
root/
├── [if enable_aws] → modules/aws/vpc/
│                     modules/aws/security/
│                     modules/aws/compute/
│
├── [if enable_azure] → modules/azure/network/
│                       modules/azure/nsg/
│                       modules/azure/compute/
│
└── [if enable_gcp] → modules/gcp/network/
                      modules/gcp/firewall/
                      modules/gcp/compute/
```

## Root Module Orchestration

**`root/main.tf`**: Instantiates all provider modules with conditional blocks:

```hcl
module "aws_vpc" {
  count  = var.enable_aws ? 1 : 0
  source = "./modules/aws/vpc"
  # ... provider-specific inputs
}
```

**Variable Flow**:

1. User provides `env/dev.tfvars`
2. `root/variables.tf` validates and defaults
3. `root/locals.tf` computes prefixes, tagging, CIDR allocations
4. `root/main.tf` passes to module instances
5. Each module enforces its own contracts (type checking, bounds)

**State Architecture**:

- **Single state file per environment** (dev, prod)
- Remote backends: S3 (AWS), Blob Storage (Azure), GCS (GCP)
- State locking prevents concurrent applies
- Sensitive data (passwords, keys) marked as `sensitive = true`

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
  Environment = var.environment      # dev | staging | prod
  Project     = var.project_name     # stratus
  ManagedBy   = "terraform"          # Automation signal
  CreatedDate = timestamp()           # When provisioned
  Owner       = var.owner_email      # devops@example.com
  [additional_tags]                  # User-provided overrides
}
```

**Audit**: By `Owner`, `CreatedDate`; filter by `ManagedBy="terraform"`.  
**RBAC**: Azure/GCP IAM roles keyed on `Owner`; Stratus Gateway inventory filters by owner email.

## VM Configuration

### Linux VMs (Ubuntu 24.04 LTS)

- Instance types: AWS t3.micro (dev), t3.large (prod)
- Image: Latest Ubuntu 24.04 LTS (updated monthly)
- SSH: Public key from `~/.ssh/stratus-terraform.pub`
- Storage: 30 GB root volume
- Network: Public IP on AWS (via IGW), private on Azure/GCP (NAT)

### Windows VMs (Windows Server 2022)

- Instance types: AWS t3.small, Azure Standard_B2s, GCP e2-small
- Image: Latest Windows Server 2022 (patched)
- RDP: Admin user (default: "azureuser"), password from `TF_VAR_windows_admin_password`
- Storage: 32 GB root volume
- Network: Private IP (Windows typically doesn't need direct internet in test scenarios)

## State Management

**Backend Configuration** (per environment):

```hcl
# backend-dev.hcl
bucket         = "stratus-terraform-state-dev"
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

**Access Control**:

- S3 bucket policy: Only terraform CI user can read/write
- Azure: RBAC on storage account
- GCP: IAM roles on GCS bucket

## Scaling Considerations

### Horizontal Scaling

- Increase `linux_vm_count` / `windows_vm_count` → Creates N instances per provider
- Uses `count` in compute modules: `count.index` for unique naming, IP assignment
- Example: `linux_vm_count = 5` → 5 Linux VMs per provider × 3 providers = 15 Linux VMs total

### Provider-Specific Limits

- **AWS**: EC2 instance limit (default 10 on-demand), security group rules limit (120)
- **Azure**: VNets per subscription (50), VMs per region (100+)
- **GCP**: Compute instances per project (flexible; quotas by machine type)

### Cost Scaling

- `dev` sizing: ~$5-10/month (free tier eligible)
- `prod` sizing: ~$150-250/month

## Inventory

**Inventory Export**:

```bash
terraform output -json inventory > inventory.json
```

**Inventory Format**:

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
  }
}
```

## Testing & Validation

**Linting** (`tflint`):

- Naming conventions (resource names match pattern)
- Unused variables/outputs
- Cloud-specific best practices (e.g., enable encryption, versioning)

**Validation** (`terraform validate`):

- Syntax correctness
- Required variable presence
- Type mismatches

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
   - SSH private key in ~/.ssh (user-managed, not in repo)
   - Windows password via env var (not in tfvars, never in repo)

## Troubleshooting Guide

**Common Issues**:

1. **"Error: invalid type for ..."** → Type mismatch in tfvars. Verify object keys.
2. **"Error: resource already exists"** → State mismatch (resource created outside Terraform). Use `terraform import` or `terraform destroy` + recreate.
3. **"Error: subnet CIDR conflicts"** → CIDR overlaps. Check `aws_vpc_cidr`, `azure_vnet_cidr`, `gcp_network_cidr` in locals.
4. **Windows admin password rejected** → Password doesn't meet Azure/GCP complexity (12+ chars, mixed case, numbers, symbols).
5. **SSH key not found** → Missing `~/.ssh/stratus-provinfra.pub`. Run `generate-ssh-key.sh`.

**Debug Steps**:

```bash
terraform refresh  # Re-sync state with cloud
terraform state list  # See all managed resources
terraform state show aws_instance.linux[0]  # Inspect one resource
terraform console  # REPL for HCL evaluation
```
