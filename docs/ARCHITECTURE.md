# Stratus-Terraform Architecture

## Design Principles

### 1. **Modularity**
- **Shared modules** (`modules/shared/*`): Centralize DRY concerns — naming, tagging, security rules.
- **Provider modules** (`modules/aws/*`, `modules/azure/*`, `modules/gcp/*`): Each provider is fully isolated. No cross-provider imports.
- **Root orchestration** (`root/`): Single point of composition; coordinates provider modules and applies unified variables.

### 2. **Maintainability**
- **Single Responsibility**: Each module owns one logical unit (VPC networking, VM compute, security groups).
- **Clear Contracts**: Every module has explicit `variables.tf`, `main.tf`, `outputs.tf`.
- **No Magic**: All naming, tagging, and defaults are explicit; no hidden computed values.
- **Versioning**: Pin provider versions in `terraform.tf`; use `~>` for patch-level flexibility.

### 3. **DRY (Don't Repeat Yourself)**
- **Shared tagging**: All resources inherit `local.common_tags` from `root/locals.tf`.
- **Naming conventions**: Standardized format `{env}-{project}-{component}-{index}` enforced in `modules/shared/naming/`.
- **Security rules**: SSH/RDP rules defined once in `modules/shared/security_group_rules/`, used by all providers.

### 4. **Environment Layering**
- **Three environments**: `dev` (testing), `staging` (realistic), `prod` (hardened).
- **Per-environment vars**: `env/dev.tfvars`, `env/staging.tfvars`, `env/prod.tfvars` override defaults.
- **Enable/disable per-provider**: Set `enable_aws=true/false` to deploy only to desired clouds.

## Module Dependency Graph

```
root/
├── [depends on] → modules/shared/naming/
├── [depends on] → modules/shared/tags/
├── [depends on] → modules/shared/security_group_rules/
│
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

**Key**: Modules share only `modules/shared/*` and root-level `locals`. No lateral module dependencies.

## Shared Modules

### `modules/shared/naming/`
**Purpose**: Centralize naming logic for consistency across all providers.

**Inputs**:
- `environment`: dev/staging/prod
- `project_name`: e.g., "stratus"
- `linux_count`: Number of Linux VMs
- `windows_count`: Number of Windows VMs

**Outputs**:
- `name_prefix`: Base prefix (e.g., "dev-stratus")
- `aws_prefix`, `azure_prefix`, `gcp_prefix`: Provider-specific (GCP uses underscores)
- `linux_names[]`: Computed names (e.g., ["dev-stratus-linux-1", "dev-stratus-linux-2"])
- `windows_names[]`: Computed names (e.g., ["dev-stratus-windows-1", "dev-stratus-windows-2"])
- `resource_names`: All auxiliary resource names (vpc, subnet, sg, nat-gw, etc.)

**Example Usage in AWS Module**:
```hcl
module "shared_naming" {
  source = "./modules/shared/naming"
  environment = var.environment
  project_name = var.project_name
  linux_count = var.linux_vm_count
  windows_count = var.windows_vm_count
}

# Use in compute module:
for_each = toset(module.shared_naming.linux_names)
# Creates instances: dev-stratus-linux-1, dev-stratus-linux-2, ...
```

### `modules/shared/tags/`
**Purpose**: Standardize tagging across all resources for cost allocation and compliance.

**Inputs**:
- `environment`, `project_name`, `owner_email`, `cost_center`, `additional_tags`

**Outputs**:
- `common_tags`: Map of standard tags (Environment, Project, ManagedBy, Owner, CostCenter, CreatedDate)

**Applied to**:
- Every EC2, VM, firewall rule, network resource
- Enables cost tracking, audit trails, and RBAC filtering

**Example Tags**:
```hcl
{
  Environment = "dev"
  Project     = "stratus"
  ManagedBy   = "terraform"
  Owner       = "devops@example.com"
  CostCenter  = "engineering"
  CreatedDate = "2025-07-10"
}
```

### `modules/shared/security_group_rules/`
**Purpose**: Define SSH (Linux) and RDP (Windows) rules once; reuse across providers.

**Inputs**:
- `allow_ssh_from_cidrs`: List of CIDRs allowed SSH access (default: ["0.0.0.0/0"])
- `allow_rdp_from_cidrs`: List of CIDRs allowed RDP access (default: ["0.0.0.0/0"])
- `allow_internal_traffic`: Boolean to allow intra-VPC communication

**Outputs**:
- `ssh_ingress_rules`: Ingress rule map (port 22, protocol tcp)
- `rdp_ingress_rules`: Ingress rule map (port 3389, protocol tcp)
- `common_egress_rules`: All outbound traffic (0.0.0.0/0)

## Provider-Specific Modules

### AWS Module Structure

**`modules/aws/vpc/`**
- Creates: VPC, 2 subnets (Linux/Windows), Internet Gateway, NAT Gateway, Route Tables, Network ACL
- Networking strategy:
  - **Linux subnet** (public): Direct internet access via IGW; publicly routable instances
  - **Windows subnet** (private): Internet via NAT Gateway; no inbound from internet
- Outputs: VPC ID, subnet IDs, IGW/NAT IDs, route table IDs

**`modules/aws/security/`**
- Creates: Security Group, SSH Key Pair
- Allows: Inbound SSH (22), RDP (3389) per shared rules; all outbound
- Outputs: Security group ID, key pair name

**`modules/aws/compute/`**
- Creates: EC2 instances (Linux + Windows)
- Uses: Data sources to look up latest Ubuntu/Windows AMIs
- Instance config:
  - Root volume: 30 GB gp3
  - Monitoring: CloudWatch detailed monitoring enabled
  - Tags: Auto-applied from shared tags + instance-specific Name tag
- Outputs: Instance IDs, private IPs, public IPs (Linux only)

### Azure Module Structure

**`modules/azure/network/`**
- Creates: Resource Group, VNet, 2 subnets, Public IPs
- Networking:
  - **Linux subnet** (10.1.1.0/24): Assigned public IPs; public endpoint access
  - **Windows subnet** (10.1.2.0/24): Private IPs; no public endpoint
- Outputs: Resource group name, VNet ID, subnet IDs

**`modules/azure/nsg/`**
- Creates: Network Security Group
- Rules: SSH (22), RDP (3389), all outbound
- Outputs: NSG ID (associated with both subnets)

**`modules/azure/compute/`**
- Creates: Virtual Machines (Linux + Windows)
- Uses: Data sources for Ubuntu/Windows image publishers and SKUs
- VM config:
  - OS disk: 32 GB Standard SSD
  - Windows: Managed admin user + password (from TF var)
  - Tags: Standard tags auto-applied
- Outputs: VM IDs, private IPs, public IPs (if allocated)

### GCP Module Structure

**`modules/gcp/network/`**
- Creates: VPC Network, 2 subnets (Linux/Windows), Cloud NAT
- Networking:
  - Both subnets private by default; NAT Gateway provides outbound internet
  - Cloud NAT auto-allocates IPs for instances
- Outputs: Network name, subnet names

**`modules/gcp/firewall/`**
- Creates: Firewall rules (SSH, RDP, IAP tunnel)
- Rules:
  - SSH (22): From 0.0.0.0/0 (or restricted CIDR)
  - RDP (3389): From 0.0.0.0/0 (or restricted CIDR)
  - IAP tunnel (allow if running in GCP project)
- Outputs: Firewall rule IDs

**`modules/gcp/compute/`**
- Creates: Compute Instances (Linux + Windows)
- Uses: Data sources for Ubuntu/Windows image families (latest stable)
- Instance config:
  - Boot disk: 32 GB pd-ssd (balanced performance)
  - Metadata: SSH keys, Windows startup scripts
  - Service account: Default compute service account
  - Tags: Instance labels (GCP's tagging mechanism)
- Outputs: Instance IDs, names, internal/external IPs

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
1. User provides `env/dev.tfvars` (or `env/staging.tfvars`)
2. `root/variables.tf` validates and defaults
3. `root/locals.tf` computes prefixes, tagging, CIDR allocations
4. `root/main.tf` passes to module instances
5. Each module enforces its own contracts (type checking, bounds)

**State Architecture**:
- **Single state file per environment** (dev, staging, prod)
- Remote backends: S3 (AWS), Blob Storage (Azure), GCS (GCP)
- State locking prevents concurrent applies
- Sensitive data (passwords, keys) marked as `sensitive = true`

## Naming Convention

All resources follow: `{environment}-{project_name}-{component}-{index}`

Examples:
- VPC: `dev-stratus-vpc`
- Subnets: `dev-stratus-subnet-linux`, `dev-stratus-subnet-windows`
- Linux VMs: `dev-stratus-linux-1`, `dev-stratus-linux-2`
- Windows VMs: `dev-stratus-windows-1`, `dev-stratus-windows-2`
- Security Group: `dev-stratus-sg`
- SSH Key: `dev-stratus-key`

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
  CostCenter  = var.cost_center      # engineering
  [additional_tags]                  # User-provided overrides
}
```

**Cost Tracking**: By `CostCenter`, drill down by `Environment` and `Project`.  
**Audit**: By `Owner`, `CreatedDate`; filter by `ManagedBy="terraform"`.  
**RBAC**: Azure/GCP IAM roles keyed on `Owner`; Stratus Gateway inventory filters by owner email.

## VM Configuration

### Linux VMs (Ubuntu 24.04 LTS)
- Instance types: AWS t3.micro (dev), t3.medium (staging), t3.large (prod)
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

## Deployment Workflow

```
1. [Developer] Edits env/*.tfvars or modules
                ↓
2. [CI/Linting] terraform fmt -recursive
                terraform validate
                tflint -c tests/tflint.hcl
                ↓
3. [Plan] terraform plan -var-file=env/dev.tfvars -out=tfplan
          → Review: resource additions/deletions/changes
          ↓
4. [Apply] terraform apply tfplan
           → Create/update resources on cloud providers
           ↓
5. [Verify] terraform output -json > inventory.json
            → Query VMs; verify tags, IPs, naming
            ↓
6. [Integrate] Feed inventory.json to Stratus Gateway config
               → Gateway refreshes; discovers VMs
               ↓
7. [Test] Stratus Gateway: Connect → SSH/RDP to VMs
```

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
- `staging` sizing: ~$50-80/month
- `prod` sizing: ~$150-250/month

## Integration with Stratus Gateway

**Inventory Export**:
```bash
terraform output -json inventory > stratus-inventory.json
```

**Inventory Format**:
```json
{
  "aws": {
    "total_vms": 4,
    "vms": [
      {
        "id": "i-0123456789abc",
        "name": "dev-stratus-linux-1",
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

**Stratus Gateway Usage**:
1. Load inventory JSON via API or file
2. Filter by environment/owner via tags
3. Discover VMs; cache in local inventory
4. On "Connect" click → Use provider CLI (aws ssm, az ssh, gcloud compute ssh)

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
   - Cloud credentials via awscli/azurecli/gcloud config (not in repo)

## CI/CD Integration

**GitHub Actions** (`.github/workflows/validate.yml`):
```yaml
- terraform fmt -check
- terraform validate
- tflint
- terraform plan -var-file=env/dev.tfvars (review on PR)
```

**Deployment** (`.github/workflows/plan-and-apply.yml`):
```yaml
# On merge to main:
- terraform apply tfplan
- Export inventory → upload to artifact store
- Notify Slack: "Stratus-Terraform deployed"
```

## Troubleshooting Guide

**Common Issues**:

1. **"Error: invalid type for ..." ** → Type mismatch in tfvars. Verify object keys.
2. **"Error: resource already exists"** → State mismatch (resource created outside Terraform). Use `terraform import` or `terraform destroy` + recreate.
3. **"Error: subnet CIDR conflicts"** → CIDR overlaps. Check `aws_vpc_cidr`, `azure_vnet_cidr`, `gcp_network_cidr` in locals.
4. **Windows admin password rejected** → Password doesn't meet Azure/GCP complexity (12+ chars, mixed case, numbers, symbols).
5. **SSH key not found** → Missing `~/.ssh/stratus-terraform.pub`. Run `generate-ssh-key.sh`.

**Debug Steps**:
```bash
terraform refresh  # Re-sync state with cloud
terraform state list  # See all managed resources
terraform state show aws_instance.linux[0]  # Inspect one resource
terraform console  # REPL for HCL evaluation
```

---

**Last Updated**: 2025-07-10  
**Author**: Stratus Terraform Team  
**Related**: `/docs/DEPLOYMENT.md`, `/docs/AWS_SETUP.md`, `/docs/AZURE_SETUP.md`, `/docs/GCP_SETUP.md`
