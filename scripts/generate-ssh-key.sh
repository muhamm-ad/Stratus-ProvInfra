#!/usr/bin/env bash
set -euo pipefail

KEY_PATH="${HOME}/.ssh/stratus-terraform"

if [ -f "${KEY_PATH}" ]; then
  echo "SSH key already exists at ${KEY_PATH}"
  exit 0
fi

ssh-keygen -t ed25519 -f "${KEY_PATH}" -N "" -C "stratus-provinfra"
echo "SSH key generated:"
echo "  Private: ${KEY_PATH}"
echo "  Public:  ${KEY_PATH}.pub"
