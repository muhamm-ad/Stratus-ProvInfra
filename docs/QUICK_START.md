# Stratus-ProvInfra Quick Start

A multi-cloud infrastructure-as-code project to provision test VMs across AWS, Azure, and GCP for validating the Stratus Gateway desktop application.

## Architecture Overview

- **VMs**: Optional Linux and/or Windows workloads per cloud
- **Provider-specific modules**: `modules/aws/*`, `modules/azure/*`, `modules/gcp/*` — isolated per provider
- **Per-cloud root configs**: `root/aws/`, `root/azure/`, `root/gcp/` — each a fully
  independent Terraform root with its own provider block, state, and workspaces.
  Which cloud gets deployed is chosen by which root you run, not by which
  `cloud_providers` keys you populate — Terraform configures every declared
  `provider` block regardless of resource usage, so this is the only way to make a
  cloud provider truly optional. See [ARCHITECTURE.md](ARCHITECTURE.md) for why.
- **Environment layering**: `env/dev.tfvars`, `env/prod.tfvars` — shared across all
  three roots; each root just reads the slice relevant to it

## Configuration Model

Two variables, in the same shared tfvars file, control what gets deployed:

### `cloud_providers` — connection details per cloud

Each root only reads its own slice (`root/aws` reads `.aws`, etc.), but you can
keep all three filled in in one file. The root you run requires its own slice to
be present.

```hcl
cloud_providers = {
  aws = {
    region       = "us-east-1"
    access_key   = ""
    secret_key   = ""
    access_token = ""
    vpc_cidr     = "10.0.0.0/16"
  }
  azure = { ... }
  gcp   = { ... }
}
```

### `instances` — which operating systems

Include only the OS blocks you need. Defaults to `{}` (no VMs).

```hcl
instances = {
  linux = {
    count = 1
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
  # Omit windows to skip Windows VMs and their subnets
}
```

When a block is present, all nested fields (`count`, `instance_type`, `cidr`) are required.

## Prerequisites

1. **OpenTofu** v1.5+ or **Terraform** v1.5+

2. **Cloud CLI Tools (optional)**
   - AWS: `aws cli v2` + `aws configure` with credentials
   - Azure: `az cli` + `az login` with credentials
   - GCP: `gcloud cli` + `gcloud auth application-default login`

3. **SSH Key** (for Linux VMs)

   ```bash
   ./scripts/generate-ssh-key.sh
   # Creates ~/.ssh/stratus-provinfra (private) and ~/.ssh/stratus-provinfra.pub
   ```

   Point `security.ssh.public_key_path` in your tfvars at the `.pub` file (defaults
   to `~/.ssh/stratus-provinfra.pub` in the example tfvars).

4. **Windows Admin Password** (for Azure/GCP Windows VMs)

   Set it directly in your tfvars under `security.windows.password` (see
   `env/dev.tfvars.exemple`), or override it without putting it in a file:

   ```bash
   export TF_VAR_security='{"ssh":{"public_key_path":"~/.ssh/stratus-provinfra.pub"},"windows":{"username":"azureuser","password":"MySecureP@ssw0rd123"}}'
   ```

## Quick Setup

### 1. Clone and Initialize

```bash
git clone https://github.com/muhamm-ad/stratus-provinfra.git
cd stratus-provinfra

# Copy and edit environment config
cp env/dev.tfvars.exemple env/dev.tfvars

# Initialize Terraform for the cloud(s) you want and select the dev workspace
./scripts/init.sh aws dev
./scripts/init.sh azure dev   # repeat for each cloud you plan to use
./scripts/init.sh gcp dev
```

State is stored **locally** on your machine, one directory per cloud
(`root/aws/`, `root/azure/`, `root/gcp/`). Within each cloud, `dev`/`prod` use
separate Terraform workspaces so their state files never overlap.

```bash
# List workspaces for a given cloud
cd root/aws && terraform workspace list

# Switch environment before manual commands
terraform workspace select prod
```

### 2. Configure Credentials

**AWS**:

```bash
aws configure
# Enter: Access Key ID, Secret Key, Region (us-east-1), Output format (json)
```

**Azure**:

```bash
az login
az account show  # Verify subscription
```

**GCP**:

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

Set provider details in `env/dev.tfvars` under `cloud_providers`.

### 3. Plan and Deploy

```bash
# From repository root - pick a cloud
./scripts/deploy.sh aws dev

# Or manually from root/aws
cd root/aws
terraform fmt -recursive ../..
terraform validate
terraform plan -var-file=../../env/dev.tfvars -out=tfplan
terraform apply tfplan
```

Repeat with `azure`/`gcp` (and `root/azure`/`root/gcp`) to deploy additional clouds -
each is a fully independent apply with its own state.

### 4. View Outputs

Run these from within the cloud's root directory (e.g. `root/aws`):

```bash
# Get all deployed resource details
terraform output -json > inventory.json

# View this cloud's instances
terraform output -json instances | jq .

# This cloud's inventory (Stratus Gateway format)
terraform output -json inventory | jq .
```

## Common Tasks

### Deploy Only AWS

Just run the AWS root - `azure`/`gcp` blocks in the shared tfvars are ignored
unless you separately run those roots:

```bash
./scripts/deploy.sh aws dev
```

### Deploy Only Linux VMs (No Windows)

Remove the `windows` block from `instances`:

```hcl
instances = {
  linux = {
    count = 1
    instance_type = { aws = "t3.micro", azure = "Standard_B1s", gcp = "e2-micro" }
    cidr          = { aws = "10.0.1.0/24", azure = "10.1.1.0/24", gcp = "10.2.1.0/24" }
  }
}
```

### Deploy Networking Only (No VMs)

```hcl
instances = {}
```

### Destroy Everything

```bash
./scripts/destroy.sh aws dev --confirm
# Repeat per cloud - destroy.sh only ever tears down one cloud's state at a time
```

### Update VM Sizing

Edit `instances.<os>.instance_type` in `env/dev.tfvars`, then from `root/<cloud>`:

```bash
terraform plan -var-file=../../env/dev.tfvars
terraform apply -var-file=../../env/dev.tfvars
```

### Scale VM Count

Edit `instances.<os>.count` in `env/dev.tfvars`:

```hcl
instances = {
  linux = {
    count = 5
    # ...
  }
}
```

### Add Tags to All Resources

```bash
# from root/<cloud>
terraform plan -var-file=../../env/dev.tfvars \
  -var='additional_tags={"Team":"Platform","Cost":"100"}'
```

## Outputs and Integration with Stratus

After deployment, each cloud's `inventory` output contains that cloud's VM details
(single-cloud shaped - there's no combined `aws`/`azure`/`gcp` wrapper since each
root only ever knows about one cloud):

```json
{
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
}
```

Export to a JSON file (done automatically by `deploy.sh <cloud>`):

```bash
terraform output -json inventory > stratus-inventory-aws.json
```

If you deployed multiple clouds, merge their inventory files yourself (e.g. with
`jq -n`) to get a single combined view for Stratus Gateway.

## Troubleshooting

### AWS Credential Errors

```bash
aws sts get-caller-identity
```

### Azure Subscription Errors

```bash
az account list
az account set --subscription "SUBSCRIPTION_ID"
```

### GCP Project Not Found

```bash
gcloud projects list
# Set project_id in cloud_providers.gcp in your tfvars
```

### Type Validation Errors

If Terraform reports missing attributes, ensure every field inside a present `cloud_providers` or `instances` block is set. Optional blocks must be omitted entirely — do not set them to `null` in tfvars.

### `cloud_providers.<cloud> to be set` validation error

You ran `deploy.sh <cloud>` but that cloud's block is missing from your tfvars.
Add the block (e.g. `cloud_providers.azure`) or run a different cloud.

### `azurerm`/`google` auth errors while deploying AWS

Shouldn't happen: `root/aws` only ever declares the `aws` provider. If you see
this, double check you're running commands from `root/aws`, not an old/incorrect
directory.

### State / workspace issues

Always match the workspace to the tfvars file you are using, per cloud:

```bash
./scripts/init.sh aws dev          # select or create the dev workspace under root/aws
terraform plan -var-file=../../env/dev.tfvars   # from root/aws
```

Using `dev.tfvars` while on the `prod` workspace (or vice versa) can corrupt or
replace the wrong infrastructure. The deploy and destroy scripts handle workspace
selection automatically, per cloud.

### SSH Access to Linux VMs (AWS)

```bash
# from root/aws
PUB_IP=$(terraform output -json instances | jq -r '.linux_instances[0].public_ip')
ssh -i ~/.ssh/stratus-provinfra ubuntu@$PUB_IP
```

## Cost Estimation

**Development** (free tier + minimal):

- AWS: t3.micro/t3.small (eligible for free tier)
- Azure: Standard_B1s (free tier first 12 months)
- GCP: e2-micro (always free)
- **Estimated monthly**: ~$5-10 (mostly storage/data transfer)

**Production** (hardened):

- AWS: t3.large + backups
- Azure: Standard_D2s_v3 + redundancy
- GCP: n1-standard-2 + backup snapshots
- **Estimated monthly**: ~$150-250

## Next Steps

1. **Integrate with Stratus Gateway**: Export inventory (per cloud) and configure Stratus to discover these VMs
2. **Add monitoring**: CloudWatch (AWS), Monitor (Azure), Cloud Monitoring (GCP)
3. **Harden security**: Restrict SSH/RDP to your IP, add bastion hosts
4. **Scale to production**: Use `env/prod.tfvars` with larger instances and backups
5. **CI/CD**: Set up GitHub Actions to validate and plan changes on PR, per `root/<cloud>`

## Contributing

- Branch: `feature/<feature-name>`
- Code style: `terraform fmt -recursive`
- Linting: `tflint` (rules in `tflint.hcl` at the repo root)
- Validation: `terraform validate` + `terraform plan` per `root/<cloud>` (no surprises)
