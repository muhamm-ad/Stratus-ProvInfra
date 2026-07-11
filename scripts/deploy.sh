#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root"
TFVARS="${SCRIPT_DIR}/../env/${ENV}.tfvars"

if [ ! -f "${TFVARS}" ]; then
  echo "Environment file not found: ${TFVARS}"
  exit 1
fi

cd "${ROOT_DIR}"

echo "==> Formatting..."
terraform fmt -recursive ..

echo "==> Validating..."
terraform validate

echo "==> Planning (${ENV})..."
terraform plan -var-file="${TFVARS}" -out=tfplan

read -r -p "Apply plan? [y/N] " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
  terraform apply tfplan
  terraform output -json inventory > "../stratus-inventory.json"
  echo "Inventory exported to stratus-inventory.json"
else
  echo "Apply cancelled."
fi
