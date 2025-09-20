SHELL := /bin/bash

.PHONY: all help check-env lint add-ips sync deploy secrets-scan lint-security bootstrap-argocd

# Require explicit ENV (stage|prod)
check-env:
	@if [ -z "$(ENV)" ]; then \
		echo "ERROR: ENV is not set (use ENV=stage or ENV=prod)"; \
		exit 1; \
	fi
	@if [ "$(ENV)" != "stage" ] && [ "$(ENV)" != "prod" ]; then \
		echo "ERROR: ENV must be 'stage' or 'prod'"; \
		exit 1; \
	fi

# Full cycle: linters → IP → sync → deploy
all: check-env lint add-ips sync deploy

# Help
help:
	@echo "Targets:"
	@echo "  all              - Full pipeline (lint → add-ips → sync → deploy)"
	@echo "  lint             - Run pre-commit linters (ansible-lint, yamllint, shellcheck)"
	@echo "  add-ips          - Update ansible/inventories/$${ENV}/hosts.yaml"
	@echo "  sync             - Sync ansible/ to master node"
	@echo "  deploy           - Run ansible-playbook on master node"
	@echo "  bootstrap-argocd - One-time bootstrap of Argo CD (only argocd role)"
	@echo "  secrets-scan     - Run gitleaks scan for secrets"
	@echo "  lint-security    - Linters + secrets scan"

# DevSecOps checks (pre-commit: ansible-lint, yamllint, shellcheck)
lint:
	pre-commit run --all-files

# Update inventory IPs for environment
add-ips: check-env
	./add_ips_to_hosts.sh $(ENV)

# Sync ansible/ and helper files to master node
sync: check-env
	./sync_to_master.sh $(ENV)

# Run playbook on master (full stack deployment)
deploy: check-env
	./run_ansible_on_master.sh $(ENV)

# One-time bootstrap Argo CD (only argocd role)
bootstrap-argocd: check-env
	./run_ansible_on_master.sh $(ENV) --tags argocd

# Scan for secrets
secrets-scan:
	gitleaks detect --source . --redact --config .gitleaks.toml

# All security checks: linters + secrets scan
lint-security: lint secrets-scan
