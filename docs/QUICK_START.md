# Stratus-ProvInfra Quick Start

A multi-cloud infrastructure-as-code project to provision test VMs across AWS, Azure, and GCP for validating the Stratus Gateway desktop application.

## Architecture Overview

- **VMs**: Optional Linux and/or Windows workloads per enabled cloud provider
- **Provider-specific modules**: `modules/aws/*`, `modules/azure/*`, `modules/gcp/*` — isolated per provider
- **Root module**: `root/` — orchestrates all providers and module composition
- **Environment layering**: `env/dev.tfvars`, `env/prod.tfvars`

## Configuration Model

Two variables control what gets deployed:

### `cloud_providers` — which clouds

Include only the provider blocks you need. At least one is required.

```hcl
cloud_providers = {
  aws = {
    region       = "us-east-1"
    access_key   = ""
    secret_key   = ""
    access_token = ""
    vpc_cidr     = "10.0.0.0/16"
  }
  # Omit azure and gcp to deploy AWS only
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
   # Creates ~/.ssh/stratus-terraform and copies the public key to keys/
   ```

4. **Windows Admin Password** (for Azure/GCP Windows VMs)

   ```bash
   export TF_VAR_security='{"ssh":{"public_key_path":"../keys/stratus-provinfra.pub"},"windows":{"username":"azureuser","password":"MySecureP@ssw0rd123"}}'
   ```

## Quick Setup

### 1. Clone and Initialize

```bash
git clone https://github.com/muhamm-ad/stratus-provinfra.git
cd stratus-provinfra

# Copy and edit environment config
cp env/dev.tfvars.exemple env/dev.tfvars

# Initialize Terraform and select the dev workspace
./scripts/init.sh dev
```

State is stored **locally** on your machine. Each environment (`dev`, `prod`) uses a
separate Terraform workspace so their state files never overlap.

```bash
# List workspaces
cd root && terraform workspace list

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
# From repository root
./scripts/deploy.sh dev

# Or manually from root/
terraform fmt -recursive ..
terraform validate
terraform plan -var-file=../env/dev.tfvars -out=tfplan
terraform apply tfplan
```

### 4. View Outputs

```bash
# Get all deployed resource details
terraform output -json > inventory.json

# View AWS instances
terraform output -json aws_instances | jq .

# View Azure instances
terraform output -json azure_instances | jq .

# View GCP instances
terraform output -json gcp_instances | jq .

# Unified inventory
terraform output -json inventory | jq .
```

## Common Tasks

### Deploy Only AWS

Remove `azure` and `gcp` from `cloud_providers` in `env/dev.tfvars`:

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
./scripts/destroy.sh dev --confirm
```

### Update VM Sizing

Edit `instances.<os>.instance_type` in `env/dev.tfvars`, then:

```bash
terraform plan -var-file=../env/dev.tfvars
terraform apply -var-file=../env/dev.tfvars
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
terraform plan -var-file=../env/dev.tfvars \
  -var='additional_tags={"Team":"Platform","Cost":"100"}'
```

## Outputs and Integration with Stratus

After deployment, the `inventory` output contains all VM details:

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

Export to a JSON file:

```bash
terraform output -json inventory > stratus-inventory.json
```

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

### State / workspace issues

Always match the workspace to the tfvars file you are using:

```bash
./scripts/init.sh dev          # select or create dev workspace
terraform plan -var-file=../env/dev.tfvars
```

Using `dev.tfvars` while on the `prod` workspace (or vice versa) can corrupt or
replace the wrong infrastructure. The deploy and destroy scripts handle workspace
selection automatically.

### SSH Access to Linux VMs (AWS)

```bash
PUB_IP=$(terraform output -json aws_instances | jq -r '.linux_instances[0].public_ip')
ssh -i ~/.ssh/stratus-terraform ubuntu@$PUB_IP
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

1. **Integrate with Stratus Gateway**: Export inventory and configure Stratus to discover these VMs
2. **Add monitoring**: CloudWatch (AWS), Monitor (Azure), Cloud Monitoring (GCP)
3. **Harden security**: Restrict SSH/RDP to your IP, add bastion hosts
4. **Scale to production**: Use `env/prod.tfvars` with larger instances and backups
5. **CI/CD**: Set up GitHub Actions to validate and plan changes on PR

## Contributing

- Branch: `feature/<feature-name>`
- Code style: `terraform fmt -recursive`
- Linting: `tflint` (rules in `tests/tflint.hcl`)
- Validation: `terraform validate` + `terraform plan` (no surprises)
