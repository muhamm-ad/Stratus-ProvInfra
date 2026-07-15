#!/usr/bin/bash
set -euo pipefail

ENV="${1:-dev}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root"

usage() {
  cat <<EOF
Usage: $0 [dev|prod]

Initialize Terraform and select (or create) the workspace for the given environment.

Each workspace keeps a separate local state file under root/.terraform/.

Examples:
  $0 dev
  $0 prod
EOF
}

if [[ "${ENV}" == "-h" || "${ENV}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${ENV}" != "dev" && "${ENV}" != "prod" ]]; then
  echo "Invalid environment: ${ENV}"
  usage
  exit 1
fi

cd "${ROOT_DIR}"

echo "==> Initializing Terraform..."
terraform init

echo "==> Selecting workspace: ${ENV}"
if ! terraform workspace select "${ENV}" 2>/dev/null; then
  terraform workspace new "${ENV}"
fi

echo "Active workspace: $(terraform workspace show)"
echo ""
echo "Next steps:"
echo "  cp env/${ENV}.tfvars.exemple env/${ENV}.tfvars"
echo "  ./scripts/generate-ssh-key.sh"
echo "  ./scripts/deploy.sh ${ENV}"
