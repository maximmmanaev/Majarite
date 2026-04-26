SHELL := /usr/bin/env bash

PROJECT_NAME ?= majarite
ENV_FILE ?= env/dev/.env.example
DATA_DIR ?= $(PWD)/data
LOG_DIR ?= $(PWD)/logs

COMPOSE_FILES = \
	-f infra/compose/compose.base.yml \
	-f infra/compose/compose.core.yml \
	-f infra/compose/compose.prod.yml

COMPOSE = MAJARITE_PROJECT_NAME=$(PROJECT_NAME) \
	MAJARITE_DATA_DIR=$(DATA_DIR) \
	MAJARITE_LOG_DIR=$(LOG_DIR) \
	docker compose --env-file $(ENV_FILE) $(COMPOSE_FILES)

.PHONY: help
help:
	@echo "Majarite core runtime commands:"
	@echo "  make prod-config   - validate merged Docker Compose config"
	@echo "  make prod-up-core  - create runtime dirs and start core stack"
	@echo "  make prod-down     - stop core stack"
	@echo "  make prod-logs     - follow core stack logs"
	@echo "  make prod-health   - show container status and health"
	@echo "  make prod-ps       - show compose services"
	@echo "  make smoke-test    - run core runtime smoke tests"

.PHONY: prod-config
prod-config:
	$(COMPOSE) config

.PHONY: prod-up-core
prod-up-core:
	bash scripts/bootstrap/create-directories.sh
	$(COMPOSE) up -d
	@echo "Restarting nginx to refresh Docker DNS upstreams..."
	@docker restart $(PROJECT_NAME)-nginx >/dev/null 2>&1 || true

.PHONY: prod-down
prod-down:
	$(COMPOSE) down

.PHONY: prod-logs
prod-logs:
	$(COMPOSE) logs -f --tail=200

.PHONY: prod-ps
prod-ps:
	$(COMPOSE) ps

.PHONY: prod-health
prod-health:
	@echo "== Docker Compose services =="
	@$(COMPOSE) ps
	@echo
	@echo "== NGINX health =="
	@curl -fsS http://localhost:8080/health || true
	@echo
	@echo "== Container health states =="
	@docker ps --filter "name=$(PROJECT_NAME)-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"


.PHONY: smoke-test
smoke-test:
	bash scripts/deploy/smoke-test.sh
