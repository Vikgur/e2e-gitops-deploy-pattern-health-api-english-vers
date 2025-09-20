.PHONY: infra_compose-up infra_compose-down infra_compose-lint services-test docs-sync

infra_compose-up:
	@$(MAKE) -C infra_compose up

infra_compose-down:
	@$(MAKE) -C infra_compose down

infra_compose-lint:
	@echo "→ Linting infra_compose/"; \
	@dotenv-linter fix infra_compose/.env && dotenv-linter scan infra_compose/.env; \
	@yamllint -c .yamllint.yml infra_compose/; \
	@find infra_compose/ -type f -perm /u=x,g=x,o=x -print0 \
	  | xargs -0 grep -Il '^#!.*\(sh\|bash\)' \
	  | xargs -r shellcheck; \
	@gitleaks detect --source infra_compose/ --report-path infra_compose/gitleaks-report.json; \
	@echo "infra_compose lint complete"

services-test:
	# …

docs-sync:
	# …
