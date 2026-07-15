#!/usr/bin/bash
set -euo pipefail

ENV="${1:-dev}"
PLAN_ONLY="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root"
TFVARS="${SCRIPT_DIR}/../env/${ENV}.tfvars"

usage() {
  cat <<EOF
Usage: $0 [dev|prod] [--plan-only]

Deploy Stratus-ProvInfra using env/<environment>.tfvars.

Deployment scope is controlled in the tfvars file:
  - cloud_providers: include only aws, azure, and/or gcp blocks to enable
  - instances:       include only linux and/or windows blocks to provision VMs

Examples:
  $0 dev
  $0 prod --plan-only

Before first run:
  ./scripts/init.sh dev
  cp env/dev.tfvars.exemple env/dev.tfvars
  ./scripts/generate-ssh-key.sh
EOF
}

if [[ "${ENV}" == "-h" || "${ENV}" == "--help" ]]; then
  usage
  exit 0
fi

if [ ! -f "${TFVARS}" ]; then
  echo "Environment file not found: ${TFVARS}"
  echo "Copy env/${ENV}.tfvars.exemple to env/${ENV}.tfvars and edit it."
  exit 1
fi

cd "${ROOT_DIR}"

echo "==> Formatting..."
terraform fmt -recursive ..

echo "==> Validating..."
terraform validate

echo "==> Planning (${ENV})..."
terraform plan -var-file="${TFVARS}" -out=tfplan

if [[ "${PLAN_ONLY}" == "--plan-only" ]]; then
  echo "Plan saved to root/tfplan. Run 'terraform apply tfplan' to deploy."
  exit 0
fi

read -r -p "Apply plan? [y/N] " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
  terraform apply tfplan
  terraform output -json inventory > "../stratus-inventory.json"
  echo "Inventory exported to stratus-inventory.json"
else
  echo "Apply cancelled. Plan saved to root/tfplan."
fi
