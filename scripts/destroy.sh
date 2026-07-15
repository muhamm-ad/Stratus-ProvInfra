#!/usr/bin/bash
set -euo pipefail

CLOUD="${1:-}"
ENV="${2:-dev}"
CONFIRM="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root/${CLOUD}"
TFVARS="${SCRIPT_DIR}/../env/${ENV}.tfvars"

usage() {
  cat <<EOF
Usage: $0 <aws|azure|gcp> [dev|prod] --confirm

Destroy all resources managed for the given cloud and environment.

Examples:
  $0 aws dev --confirm
  $0 azure prod --confirm
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

if [ "${CONFIRM}" != "--confirm" ]; then
  echo "WARNING: This will destroy all resources in ${CLOUD}/${ENV}."
  echo "Run: $0 ${CLOUD} ${ENV} --confirm"
  exit 1
fi

cd "${ROOT_DIR}"
terraform destroy -var-file="${TFVARS}"
