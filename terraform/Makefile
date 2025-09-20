# Makefile for managing Terragrunt environments

ENV ?= stage
SERVICE ?= network

# Base environment directory
BASE_DIR = live/$(ENV)/$(SERVICE)

init:
	cd $(BASE_DIR) && terragrunt init

plan:
	cd $(BASE_DIR) && terragrunt plan

apply:
	cd $(BASE_DIR) && terragrunt apply -auto-approve

destroy:
	cd $(BASE_DIR) && terragrunt destroy -auto-approve

output:
	cd $(BASE_DIR) && terragrunt output

# Quick aliases for full environment
apply-stage:
	make apply ENV=stage SERVICE=network
	make apply ENV=stage SERVICE=vm

apply-prod:
	make apply ENV=prod SERVICE=network
	make apply ENV=prod SERVICE=vm

destroy-stage:
	make destroy ENV=stage SERVICE=vm
	make destroy ENV=stage SERVICE=network

destroy-prod:
	make destroy ENV=prod SERVICE=vm
	make destroy ENV=prod SERVICE=network

# Linting and IaC security
lint-security:
	terraform fmt -check
	terraform validate
	tflint --recursive
	checkov -d . --quiet
	gitleaks detect --source . --no-banner
	yamllint .
	devsecops_scripts/plan_json.sh
	conftest test --input json plan.json -p policy/terraform
