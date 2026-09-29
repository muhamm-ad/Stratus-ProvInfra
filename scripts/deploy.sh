#!/usr/bin/bash
set -euo pipefail

CLOUD="${1:-}"
shift || true

ENV="dev"
if [[ "${1:-}" == "dev" || "${1:-}" == "prod" ]]; then
  ENV="$1"
  shift
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root/${CLOUD}"
TFVARS="${SCRIPT_DIR}/../config/${ENV}.tfvars"

usage() {
  cat <<EOF
Usage: $0 <aws|azure|gcp> [dev|prod] [terraform apply options...]

Deploy Stratus-ProvInfra to one cloud using root/<cloud> and
config/<environment>.tfvars (shared across all three clouds - this only reads
the cloud_providers.<cloud> slice of that file).

Any extra arguments are passed through to \`terraform apply\`.

Examples:
  $0 aws dev
  $0 azure prod -auto-approve
  $0 gcp dev -target=module.compute

Before first run:
  ./scripts/init.sh aws dev
  cp config/dev.tfvars.exemple config/dev.tfvars
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
  echo "Copy config/${ENV}.tfvars.exemple to config/${ENV}.tfvars and edit it."
  exit 1
fi

cd "${ROOT_DIR}"

echo "==> Formatting..."
terraform fmt -recursive ../..

echo "==> Validating..."
terraform validate

echo "==> Applying (${CLOUD}/${ENV})..."
terraform apply -var-file="${TFVARS}" "$@"

terraform output -json inventory > "../../stratus-inventory-${CLOUD}.json"
echo "Inventory exported to stratus-inventory-${CLOUD}.json"
