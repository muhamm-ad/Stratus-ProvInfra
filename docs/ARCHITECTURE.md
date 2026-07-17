# Stratus-ProvInfra Architecture

## Design Principles

### 1. **Modularity**

- **Provider modules** (`modules/aws/*`, `modules/azure/*`, `modules/gcp/*`): Each provider is fully isolated. No cross-provider imports.
- **Per-cloud root configs** (`root/aws/`, `root/azure/`, `root/gcp/`): Each is a fully independent Terraform root — its own provider block, variables, state, and workspaces. There is no combined root; a run only ever touches one cloud, so an AWS-only deployment never configures (or authenticates to) `azurerm`/`google` at all. This is a hard Terraform constraint, not a style choice: providers are configured for every declared `provider` block regardless of resource usage, and a module called with `count`/`for_each` cannot itself contain a `provider` block — so "one cloud per root" is the only way to make a provider truly optional.

### 2. **Maintainability**

- **Single Responsibility**: Each module owns one logical unit (VPC networking, VM compute, security groups).
- **Clear Contracts**: Every module has explicit `variables.tf`, `main.tf`, `outputs.tf`.
- **No Magic**: All naming, tagging, and defaults are explicit; no hidden computed values.
- **Versioning**: Pin provider versions in `terraform.tf`; use `~>` for patch-level flexibility. Modules also declare `required_version` / `required_providers`.

### 3. **DRY (Don't Repeat Yourself)**

- **Shared tagging**: All resources inherit `local.common_tags`, computed identically in each `root/<cloud>/main.tf`.
- **Naming conventions**: Standardized format `{env}_{project}_{component}_{index}` enforced across modules.
- **Conditional composition**: OS enablement (`linux`/`windows`) derived from structured input variables within a root; cloud enablement is a directory choice (`root/<cloud>`), not a variable.

### 4. **Environment Layering**

- **Two environments**: `dev` (testing), `prod` (hardened).
- **Per-environment vars**: `env/dev.tfvars`, `env/prod.tfvars` override defaults, shared across all three per-cloud roots.
- **Cloud selection**: which cloud gets deployed is chosen by which `root/<cloud>` you run, not by which `cloud_providers` keys are populated in tfvars (see "Per-Cloud Root Configs" below).
- **Selective OS deployment**: Omit the `linux` or `windows` block in tfvars to deploy only the operating systems you want, within whichever cloud you're running.

## Configuration Variables

### `cloud_providers`

Structured object with optional `aws`, `azure`, and `gcp` blocks. The same shared
`env/<environment>.tfvars` file is passed to all three per-cloud roots, so all three
sub-blocks can be populated in one place even though a given root only reads one of them.

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

Each root only cares about its own slice: `root/aws/main.tf` reads
`var.cloud_providers.aws` (aliased to `local.aws_config`), `root/azure` reads `.azure`,
`root/gcp` reads `.gcp`. Each root's `variables.tf` validates that its own slice is
non-null (e.g. `root/aws` requires `cloud_providers.aws != null`) — if you run
`./scripts/deploy.sh aws` without an `aws` block in your tfvars, `terraform validate`
fails immediately with a clear message instead of silently doing nothing.

Empty AWS credential strings fall through to the default AWS credential chain (env vars / shared config / SSO).

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

### Identity (no `security` tfvars block)

Admin usernames are derived in each root:

```hcl
username = regex("^([^@]+)", var.owner_email)[0]
```

For example, `owner_email = "alice@example.com"` yields username `alice`. That
value is passed into compute modules (and into AWS user-data templates).

Windows initial passwords are currently set in each root's `main.tf` (not via
tfvars). Change them there before deploying to non-lab environments.

## Module Dependency Graph

Each cloud is its own root, so there's no cross-cloud `count`/conditional wiring - a
given root always instantiates its modules exactly once:

```text
root/aws/    → modules/aws/vpc/
               modules/aws/security/
               modules/aws/compute/    (+ linux-userdata.yaml, win-userdata.ps1)

root/azure/  → modules/azure/network/  (subnets per enabled OS)
               modules/azure/nsg/
               modules/azure/compute/  (per enabled OS)

root/gcp/    → modules/gcp/network/    (subnets per enabled OS + Cloud NAT)
               modules/gcp/firewall/
               modules/gcp/compute/  (per enabled OS)
```

Only the OS blocks (`linux`/`windows`) are still conditional within a root, via
`local.enable_linux` / `local.enable_windows` derived from `var.instances`.

## Root Module Orchestration

**Why three roots instead of one**: Terraform configures every declared `provider`
block during `plan`/`apply` regardless of whether any resource in the plan actually
uses it, and a module called with `count`/`for_each` cannot itself contain a `provider`
block. That means a single root with `aws`/`azurerm`/`google` all declared can never
make a provider truly optional - `azurerm` in particular always makes a real call to
Azure AD (or shells out to `az`) during `Configure`, with no "skip auth" escape hatch
(unlike `aws`'s `skip_credentials_validation` or a null `google` project). Splitting
into `root/aws`, `root/azure`, `root/gcp` sidesteps this entirely: an AWS-only run
never even has `azurerm`/`google` in `required_providers`, so there's nothing to
authenticate to.

**`root/<cloud>/main.tf`**: Instantiates that cloud's modules directly, no `count`:

```hcl
module "vpc" {
  source = "../../modules/aws/vpc"

  subnet_configs = merge(
    local.enable_linux ? { linux = { cidr = ..., az = ... } } : {},
    local.enable_windows ? { windows = { cidr = ..., az = ... } } : {}
  )
}

module "compute" {
  source = "../../modules/aws/compute"

  linux_instances   = local.enable_linux ? { ... } : null
  windows_instances = local.enable_windows ? { ... } : null
}
```

**Variable Flow**:

1. User provides `env/dev.tfvars` (shared across all three roots)
2. `root/<cloud>/variables.tf` validates types/constraints and requires its own
   `cloud_providers.<cloud>` slice to be non-null
3. `root/<cloud>/main.tf` locals alias that slice (e.g. `local.aws_config`), compute
   OS enable flags, naming prefix, username from `owner_email`, and tags
4. `root/<cloud>/main.tf` passes inputs to its modules
5. Each module creates only the resources for enabled OS workloads

**State Architecture**:

- **One root directory per cloud** (`root/aws/`, `root/azure/`, `root/gcp/`), each with
  its own `.terraform/` and provider lock file - fully isolated from the others
- **One workspace per environment** (`dev`, `prod`) within each cloud's root, with
  isolated local state
- State files stored under `root/<cloud>/terraform.tfstate.d/<workspace>/`
- No remote backend or distributed locking (suitable for local / solo use)
- Deploying to more than one cloud means running `deploy.sh`/`destroy.sh` once per
  cloud - there's no single combined multi-cloud apply

## Network Module Design

Network modules use `for_each` on `subnet_configs` so subnets are created only for enabled operating systems:

- **AWS** (`modules/aws/vpc`): `aws_subnet.workload` keyed by OS name; all workload
  subnets are public (`map_public_ip_on_launch = true`) with an IGW default route
- **Azure** (`modules/azure/network`): `azurerm_subnet.workload` keyed by OS name;
  static Standard public IPs are created for Linux VMs
- **GCP** (`modules/gcp/network`): `google_compute_subnetwork.workload` keyed by OS
  name; Cloud Router + Cloud NAT for private outbound

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

AWS also applies provider `default_tags` including `Provider = "AWS"`. Timestamps
come from `time_static` resources in each root.

**Audit**: By `Owner`, `CreatedAt`; filter by `ManagedBy="terraform"`.  
**RBAC**: Azure/GCP IAM roles keyed on `Owner`; Stratus Gateway inventory filters by owner email.

## VM Configuration

### Linux VMs (Ubuntu 24.04 LTS)

| Aspect | AWS | Azure | GCP |
|--------|-----|-------|-----|
| Image | SSM param (Canonical Ubuntu 24.04 amd64) | Canonical Jammy `24_04-lts-gen2` | `ubuntu-2404-lts` |
| Disk | 50 GB gp3, encrypted | 32 GB Premium_LRS | 32 GB pd-ssd |
| Network | Public IP (public subnet) | Public IP attached | External IP (`access_config`) |
| Auth | Cloud-init user from `owner_email` | `admin_username` from `owner_email` | Instance metadata / OS login as configured |
| User data | `linux-userdata.yaml` template | None | None |
| Monitoring | EC2 detailed monitoring on | — | — |

AWS Linux user data (`modules/aws/compute/linux-userdata.yaml`):

- Creates a single sudo user (`${username}`), no default cloud user
- Optionally runs caller-supplied `extra` shell (root currently installs Nginx)
- `lifecycle { ignore_changes = [user_data] }` so later template edits do not force replace

### Windows VMs (Windows Server 2022)

| Aspect | AWS | Azure | GCP |
|--------|-----|-------|-----|
| Image | Windows Server 2022 Full Base | 2022-Datacenter | `windows-2022` |
| Disk | 50 GB gp3, encrypted | 32 GB Premium_LRS | 32 GB pd-ssd |
| Network | Public IP (public subnet) | Private IP only | Private IP only |
| Auth | Local admin via user data | Admin credentials on VM resource | As configured on instance |
| User data | `win-userdata.ps1` template | None | None |

AWS Windows user data (`modules/aws/compute/win-userdata.ps1`):

- Creates a local admin + RDP user with an initial password
- Sets account expiry (~10 minutes after first boot)
- Installs and starts OpenSSH Server
- Optionally runs caller-supplied `extra` PowerShell (root currently installs IIS)
- Runs once via EC2Launch (no `<persist>` tag); `user_data` ignored on later applies

## State Management

**Workspace-based local state** (per cloud, per environment):

```bash
./scripts/init.sh aws dev     # terraform init (root/aws) + workspace select/new dev
./scripts/init.sh azure prod  # terraform init (root/azure) + workspace select/new prod
```

| Cloud | Workspace | Var file | State location |
|-------|-----------|----------|----------------|
| `aws` | `dev` | `env/dev.tfvars` | `root/aws/terraform.tfstate.d/dev/` |
| `aws` | `prod` | `env/prod.tfvars` | `root/aws/terraform.tfstate.d/prod/` |
| `azure` | `dev` | `env/dev.tfvars` | `root/azure/terraform.tfstate.d/dev/` |
| `gcp` | `dev` | `env/dev.tfvars` | `root/gcp/terraform.tfstate.d/dev/` |

The var file is the same across clouds; the state location differs because each
cloud has its own root directory. `deploy.sh <cloud> <env>` and
`destroy.sh <cloud> <env>` expect `init.sh <cloud> <env>` to have already selected
the right workspace.

**Sensitive Data in State**:

- Windows initial passwords and user-data content can appear in AWS state
- State files are gitignored and must not be committed

## Scaling Considerations

### Horizontal Scaling

- Increase `instances.linux.count` or `instances.windows.count` in tfvars
- Uses `count` in compute modules: `count.index` for unique naming, IP assignment
- Example: `instances.linux.count = 5`, deployed via `deploy.sh aws`, `deploy.sh azure`,
  and `deploy.sh gcp` → 5 Linux VMs per cloud (15 total across three separate applies)

### Provider-Specific Limits

- **AWS**: EC2 instance limit (default 10 on-demand), security group rules limit (120)
- **Azure**: VNets per subscription (50), VMs per region (100+)
- **GCP**: Compute instances per project (flexible; quotas by machine type)

### Cost Scaling

- `dev` sizing: ~$5-10/month per cloud (free tier eligible)
- `prod` sizing: ~$150-250/month per cloud
- Only run `deploy.sh` for the clouds you actually want; omit OS blocks to reduce cost further

## Inventory

**Inventory Export**: each cloud's `inventory` output is single-cloud shaped.
`deploy.sh <cloud>` exports it automatically after apply:

```bash
terraform output -json inventory > stratus-inventory-<cloud>.json
```

**AWS inventory fields**:

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

**Azure / GCP inventory fields**: `id`, `name`, `provider`, `os`, `ip`, `region`,
`state`. On GCP, Linux prefers external IP; Windows uses internal IP. Azure
inventory currently reports private IP for both OS types.

The AWS root's detailed `instances` output is currently commented out; use
`inventory` (or Azure/GCP `instances` outputs) instead.

If you need a single combined multi-cloud inventory file (e.g. for the Stratus
Gateway integration), merge `stratus-inventory-aws.json`, `stratus-inventory-azure.json`,
and `stratus-inventory-gcp.json` yourself (e.g. with `jq -n`) - this isn't done
automatically since a given apply only ever has one cloud's data available.

## Testing & Validation

**Linting** (`tflint`):

- Naming conventions (resource names match pattern)
- Unused variables/outputs
- Cloud-specific best practices (e.g., enable encryption, versioning)
- CI: `.github/workflows/lint.yml` (matrix: ubuntu / macos / windows)

**Validation** (`terraform validate`):

- Syntax correctness
- Required variable presence
- Type mismatches on structured objects
- CI: `.github/workflows/validate.yml` (fmt check + init/validate per `root/<cloud>`)

**Plan Review** (`terraform plan`):

- Resource addition/modification/deletion
- Variable interpolation correctness
- Dependency ordering

**Post-Deploy Verification**:

- SSH/RDP to VMs using inventory IPs
- On AWS Linux, check cloud-init logs; on AWS Windows, confirm OpenSSH/`sshd`
- Check security group rules (AWS/GCP) and NSG (Azure)
- Verify tags on all resources

## Security Best Practices

1. **Network**:
   - AWS: all workload subnets are public today; tighten SG CIDRs for production
   - Azure/GCP: Linux public (or external), Windows private; GCP uses Cloud NAT for outbound
   - Default SSH/RDP rules allow `0.0.0.0/0` — restrict to your IP before production use

2. **Access Control**:
   - AWS Linux: cloud-init creates the `owner_email` local-part user with passwordless sudo
   - AWS Windows: short-lived local admin + OpenSSH; change/rotate credentials after first login
   - Prefer key-based SSH where you wire `key_name` / SSH keys yourself

3. **Encryption**:
   - AWS root volumes encrypted (gp3)
   - State files stored locally (gitignored; protect the machine that holds them)

4. **Monitoring & Audit**:
   - CloudWatch detailed monitoring on AWS EC2
   - All infrastructure changes tagged with date, owner

5. **Credential Management**:
   - Keep `env/*.tfvars` untracked
   - Do not commit Windows passwords or cloud keys
   - Optional helper: `./scripts/generate-ssh-key.sh` creates `~/.ssh/stratus-provinfra`
     (RSA 4096); Terraform does not currently create an AWS key pair from it

## Troubleshooting Guide

**Common Issues**:

1. **"Error: invalid type for ..."** → Type mismatch in tfvars. Verify object keys match the schema in `root/<cloud>/variables.tf`.
2. **"Error: resource already exists"** → State mismatch. Use `terraform import` or `terraform destroy` + recreate.
3. **"Error: subnet CIDR conflicts"** → CIDR overlaps. Check `vpc_cidr`, `vnet_cidr`, `network_cidr` in `cloud_providers`.
4. **Windows admin password rejected** → Password doesn't meet Azure/GCP complexity (12+ chars, mixed case, numbers, symbols).
5. **Cannot SSH to AWS Linux** → Use inventory `public_ip` / `public_dns` and the username from `owner_email` (not necessarily `ubuntu`). Ensure SG allows your source IP on port 22.
6. **Unexpected resources created** → Check that omitted OS blocks are removed from tfvars, not set to empty objects.
7. **`cloud_providers.<cloud> to be set` validation error** → You ran `deploy.sh <cloud>` but that cloud's block is missing from `env/<environment>.tfvars`; add it or run a different cloud.
8. **`azurerm`/`google` auth errors while running `root/aws`** → Shouldn't happen: `root/aws` only declares the `aws` provider. If you see this, you're likely running commands from the wrong directory — `cd` into `root/aws`.
9. **User data not updating on AWS** → Expected: `lifecycle.ignore_changes = [user_data]`. Recreate the instance (taint/replace) to re-run first-boot scripts.

**Debug Steps** (run from the relevant `root/<cloud>` directory):

```bash
terraform refresh
terraform state list
terraform state show 'module.compute.aws_instance.linux[0]'
terraform console
```
