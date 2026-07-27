#!/usr/bin/bash
set -euo pipefail

CLOUD="${1:-}"
ENV="${2:-dev}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root/${CLOUD}"

usage() {
  cat <<EOF
Usage: $0 <aws|azure|gcp> [dev|prod]

Initialize Terraform and select (or create) the workspace for the given
cloud's root config and environment.

Each cloud has its own root config (root/<cloud>/) with its own provider
and state, but all three read the same env/<environment>.tfvars file -
each just uses the cloud_providers.<cloud> slice relevant to it.

Examples:
  $0 aws dev
  $0 azure prod
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

if [[ "${ENV}" != "dev" && "${ENV}" != "prod" ]]; then
  echo "Invalid environment: ${ENV}"
  usage
  exit 1
fi

cd "${ROOT_DIR}"

echo "==> Initializing Terraform (${CLOUD})..."
terraform init

echo "==> Selecting workspace: ${ENV}"
if ! terraform workspace select "${ENV}" 2>/dev/null; then
  terraform workspace new "${ENV}"
fi

echo "==> Formatting..."
terraform fmt -recursive ../..

echo "Active workspace: $(terraform workspace show)"
echo ""
echo "Next steps:"
echo "  cp env/${ENV}.tfvars.exemple env/${ENV}.tfvars"
echo "  ./scripts/generate-ssh-key.sh"
echo "  ./scripts/deploy.sh ${CLOUD} ${ENV}"
