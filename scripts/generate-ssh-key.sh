#!/usr/bin/env bash
set -euo pipefail

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_PATH="${HOME}/.ssh/stratus-provinfra"

if [ -f "${KEY_PATH}" ]; then
  echo "SSH key already exists at ${KEY_PATH}"
else
  ssh-keygen -t ed25519 -f "${KEY_PATH}" -N "" -C "stratus-provinfra"
  echo "SSH key generated:"
  echo "  Private: ${KEY_PATH}"
  echo "  Public:  ${KEY_PATH}.pub"
fi