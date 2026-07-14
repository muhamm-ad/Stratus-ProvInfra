#!/usr/bin/env bash
set -euo pipefail

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
fi

echo "Backend initialization complete."
echo "Run: cd root && terraform init -backend-config=backend-dev.hcl"
