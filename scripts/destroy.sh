#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
CONFIRM="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root"
TFVARS="${SCRIPT_DIR}/../env/${ENV}.tfvars"

if [ ! -f "${TFVARS}" ]; then
  echo "Environment file not found: ${TFVARS}"
  exit 1
fi

if [ "${CONFIRM}" != "--confirm" ]; then
  echo "WARNING: This will destroy all resources in the ${ENV} environment."
  echo "Run: $0 ${ENV} --confirm"
  exit 1
fi

cd "${ROOT_DIR}"
terraform destroy -var-file="${TFVARS}"
