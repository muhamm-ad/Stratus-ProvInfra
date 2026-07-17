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
TFVARS="${SCRIPT_DIR}/../env/${ENV}.tfvars"

usage() {
  cat <<EOF
Usage: $0 <aws|azure|gcp> [dev|prod] [terraform destroy options...]

Destroy all resources managed for the given cloud and environment.

Any extra arguments are passed through to \`terraform destroy\`.

Examples:
  $0 aws dev
  $0 azure prod -auto-approve
  $0 gcp dev -target=module.compute
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
  exit 1
fi

cd "${ROOT_DIR}"
terraform destroy -var-file="${TFVARS}" "$@"
