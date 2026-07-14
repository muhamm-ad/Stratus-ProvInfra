# Stratus-ProvInfra Quick Start

A multi-cloud infrastructure-as-code project to provision test VMs across AWS, Azure, and GCP for validating the Stratus Gateway desktop application.

## Architecture Overview

- **VMs**: X Linux + Y Windows per cloud provider (AWS, Azure, GCP) Setup by the count variables.
- **Provider-specific modules**: `modules/aws/*`, `modules/azure/*`, `modules/gcp/*` — isolated per provider
- **Root module**: `root/` — orchestrates all providers and module composition
- **Environment layering**: `env/dev.tfvars`, `env/prod.tfvars`

## Prerequisites

1. **OpenTofu** v1.5+ or **Terraform** v1.5+

2. **Cloud CLI Tools (not required)**
   - AWS: `aws cli v2` + `aws configure` with credentials
   - Azure: `az cli` + `az login` with credentials
   - GCP: `gcloud cli` + `gcloud auth application-default login`

3. **SSH Key** (for AWS Linux VMs)

   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/stratus-provinfra -N ""
   # Or use the script to generate the key:
   ./scripts/generate-ssh-key.sh
   ```

4. **Windows Admin Password** (for Azure/GCP Windows VMs)

   ```bash
   export TF_VAR_windows_admin_password='MySecureP@ssw0rd123'  # Min 12 chars, complex
   ```

## Quick Setup

### 1. Clone and Initialize

```bash
git clone https://github.com/muhamm-ad/stratus-provinfra.git
cd stratus-provinfra

# Create backend state buckets (one-time)
./scripts/init-backend.sh

# Initialize Terraform (from root module)
cd root
terraform init -backend-config=backend-dev.hcl
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
# Opens browser for authentication
az account show  # Verify subscription
```

**GCP**:

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
export TF_VAR_gcp_project_id='your-gcp-project-id'
```

### 3. Plan and Deploy

```bash
# Validate configuration
terraform fmt -recursive
terraform validate

# Plan deployment (review changes)
terraform plan -var-file=../env/dev.tfvars -out=tfplan

# Apply (deploy VMs)
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

```bash
terraform plan -var-file=../env/dev.tfvars \
  -var="enable_azure=false" \
  -var="enable_gcp=false"
```

### Deploy Only Linux VMs (no Windows)

```bash
terraform plan -var-file=../env/dev.tfvars \
  -var="windows_vm_count=0"
```

### Destroy Everything

```bash
terraform destroy -var-file=../env/dev.tfvars
```

### Update VM Sizing

```bash
# Edit env/dev.tfvars:
# linux_instance_type.aws = "t3.small"

terraform plan -var-file=../env/dev.tfvars
terraform apply -var-file=../env/dev.tfvars
```

### Add Tags to All Resources

```bash
terraform plan -var-file=../env/dev.tfvars \
  -var='additional_tags={"Team":"Platform","Cost":"100"}'
```

## Outputs and Integration with Stratus

After deployment, the `inventory` output contains all VM details in a format :

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
      },
      ...
    ]
  },
  "azure": { ... },
  "gcp": { ... }
}
```

Export into json file:

```bash
terraform output -json inventory > stratus-inventory.json
```

## Troubleshooting

### AWS Credential Errors

```bash
aws sts get-caller-identity
# Should return your AWS account info
```

### Azure Subscription Errors

```bash
az account list
az account set --subscription "SUBSCRIPTION_ID"
```

### GCP Project Not Found

```bash
gcloud projects list
export TF_VAR_gcp_project_id='correct-project-id'
```

### State Lock Issues

```bash
# If apply hangs, check for stale locks:
terraform force-unlock LOCK_ID  # Use with caution!
```

### SSH Access to Linux VMs (AWS)

```bash
# Get public IP from terraform output
PUB_IP=$(terraform output -json aws_instances | jq -r '.linux_instances[0].public_ip')

# SSH with the generated key
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
