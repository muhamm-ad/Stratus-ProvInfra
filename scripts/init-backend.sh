#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../root"
ENV="${1:-dev}"

usage() {
  cat <<EOF
Usage: $0 [dev|prod]

Initialize Terraform in root/ with the remote backend for the given environment.

Examples:
  $0 dev
  $0 prod
EOF
}

if [[ "${ENV}" == "-h" || "${ENV}" == "--help" ]]; then
  usage
  exit 0
fi

echo "Creating remote state backends for Stratus-ProvInfra..."

# AWS S3 + DynamoDB
if command -v aws &>/dev/null; then
  for env in dev prod; do
    BUCKET="stratus-provinfra-state-${env}"
    echo "Creating S3 bucket: ${BUCKET}"
    aws s3api create-bucket --bucket "${BUCKET}" --region us-east-1 2>/dev/null || true
    aws s3api put-bucket-versioning --bucket "${BUCKET}" --versioning-configuration Status=Enabled 2>/dev/null || true
    aws s3api put-bucket-encryption --bucket "${BUCKET}" \
      --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' 2>/dev/null || true
  done

  echo "Creating DynamoDB lock table: terraform-lock"
  aws dynamodb create-table \
    --table-name terraform-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1 2>/dev/null || true
else
  echo "AWS CLI not found. Skipping S3/DynamoDB backend creation."
fi

echo "Initializing Terraform backend for ${ENV}..."
cd "${ROOT_DIR}"
terraform init -backend-config="backend-${ENV}.hcl"

echo "Backend initialization complete."
echo "Next steps:"
echo "  cp env/${ENV}.tfvars.exemple env/${ENV}.tfvars"
echo "  ./scripts/generate-ssh-key.sh"
echo "  ./scripts/deploy.sh ${ENV}"
