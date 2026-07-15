#!/usr/bin/bash
set -euo pipefail

CLOUD="${1:-}"
ENV="${2:-dev}"
PLAN_ONLY="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root/${CLOUD}"
TFVARS="${SCRIPT_DIR}/../env/${ENV}.tfvars"

usage() {
  cat <<EOF
Usage: $0 <aws|azure|gcp> [dev|prod] [--plan-only]

Deploy Stratus-ProvInfra to one cloud using root/<cloud> and
env/<environment>.tfvars (shared across all three clouds - this only reads
the cloud_providers.<cloud> slice of that file).

To deploy to more than one cloud, run this script once per cloud - each
cloud is a fully independent root config with its own state.

Examples:
  $0 aws dev
  $0 azure prod --plan-only

Before first run:
  ./scripts/init.sh aws dev
  cp env/dev.tfvars.exemple env/dev.tfvars
  ./scripts/generate-ssh-key.sh
EOF
}

if [[ "${CLOUD}" == "-h" || "${CLOUD}" == "--help" || -z "${CLOUD}" ]]; then
  usage
  exit 0
fi

if [[ "${CLOUD}" != "aws" && "${CLOUD}" != "azure" && "${CLOUD}" != "gcp" ]]; then
  echo "Invalid cloud: ${CLOUD}"
  usage
  exit 1
fi

if [ ! -f "${TFVARS}" ]; then
  echo "Environment file not found: ${TFVARS}"
  echo "Copy env/${ENV}.tfvars.exemple to env/${ENV}.tfvars and edit it."
  exit 1
fi

cd "${ROOT_DIR}"

echo "==> Formatting..."
terraform fmt -recursive ../..

echo "==> Validating..."
terraform validate

echo "==> Planning (${CLOUD}/${ENV})..."
terraform plan -var-file="${TFVARS}" -out=tfplan

if [[ "${PLAN_ONLY}" == "--plan-only" ]]; then
  echo "Plan saved to root/${CLOUD}/tfplan. Run 'terraform apply tfplan' to deploy."
  exit 0
fi

read -r -p "Apply plan? [y/N] " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
  terraform apply tfplan
  terraform output -json inventory > "../../stratus-inventory-${CLOUD}.json"
  echo "Inventory exported to stratus-inventory-${CLOUD}.json"
else
  echo "Apply cancelled. Plan saved to root/${CLOUD}/tfplan."
fi
