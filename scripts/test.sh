#!/usr/bin/env bash
set -euo pipefail

bash -n scripts/verify.sh scripts/run-ephemeral.sh scripts/prepare-audit.sh scripts/check-publish-gates.sh scripts/test.sh
shellcheck scripts/verify.sh scripts/run-ephemeral.sh scripts/prepare-audit.sh scripts/check-publish-gates.sh scripts/test.sh
if command -v terraform >/dev/null 2>&1; then
  terraform fmt -recursive -check
elif command -v tofu >/dev/null 2>&1; then
  tofu fmt -recursive -check
else
  echo "Terraform or OpenTofu is required." >&2
  exit 127
fi

grep -q '8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538' scripts/verify.sh
grep -q 'd0124689230b58b4f86e7b90ac59de06404b3b6b' scripts/verify.sh
grep -q "lake -j \"\$BUILD_JOBS\" build" scripts/verify.sh
grep -q 'var.admin_cidr != "0.0.0.0/0"' infra/variables.tf
grep -q '259200' scripts/check-publish-gates.sh
echo "static checks passed"
