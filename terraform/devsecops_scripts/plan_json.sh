#!/usr/bin/env bash
set -euo pipefail

# Terragrunt initialization (update providers and modules)
terragrunt init -upgrade >/dev/null

# Generate plan
terragrunt plan -out=tfplan

# Convert plan to JSON
terraform show -json tfplan > plan.json

# Security policy check via OPA/Conftest
conftest test --input json plan.json -p ../../policy/terraform
