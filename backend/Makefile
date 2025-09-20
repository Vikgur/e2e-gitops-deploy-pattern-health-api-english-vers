.PHONY: test lint format pre-commit

test:
	pip install -r requirements-dev.txt
	pytest

lint:
	flake8 .

format:
	black . && isort .
