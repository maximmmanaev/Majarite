SHELL := /bin/bash

COMPOSE_FILES := \
	-f infra/compose/compose.base.yml \
	-f infra/compose/compose.core.yml \
	-f infra/compose/compose.prod.yml

ENV_FILE ?= .env

.PHONY: help
help:
	@echo "Majarite commands:"
	@echo "  make prod-config   - validate Docker Compose config"
	@echo "  make prod-up-core  - start core stack"
	@echo "  make prod-down     - stop core stack"
	@echo "  make prod-logs     - show logs"
	@echo "  make smoke-test    - run smoke tests"

.PHONY: prod-config
prod-config:
	docker compose --env-file $(ENV_FILE) $(COMPOSE_FILES) config

.PHONY: prod-up-core
prod-up-core:
	docker compose --env-file $(ENV_FILE) $(COMPOSE_FILES) --profile core up -d

.PHONY: prod-down
prod-down:
	docker compose --env-file $(ENV_FILE) $(COMPOSE_FILES) down

.PHONY: prod-logs
prod-logs:
	docker compose --env-file $(ENV_FILE) $(COMPOSE_FILES) logs -f --tail=200

.PHONY: smoke-test
smoke-test:
	bash scripts/deploy/smoke-test.sh
