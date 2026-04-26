# Process — NGINX Core Routing

## Назначение

NGINX в Sprint 1 является внешним HTTP entrypoint для Majarite Core Runtime.

## Routes

### /health

Проверка внешнего NGINX.

Ожидаемый ответ:

majarite-nginx-ok

### /

Проксируется в Zammad.

Целевой upstream:

zammad-nginx:8080

### /node-red/

Проксируется в Node-RED.

Целевой upstream:

node-red:1880

## Правила безопасности

- Наружу публикуется только внешний NGINX.
- Zammad runtime не публикуется напрямую.
- Node-RED не публикуется напрямую.
- PostgreSQL и Valkey не публикуются наружу.
- В production Node-RED admin должен быть закрыт VPN, allowlist или отдельной auth-защитой.

## Связанные файлы

- infra/nginx/conf.d/default.conf
- infra/nginx/snippets/proxy-common.conf
- infra/nginx/snippets/security-headers.conf
- infra/compose/compose.core.yml

## Sprint 1 routing decision

В Sprint 1 внешний NGINX проксирует Zammad напрямую в:

zammad-railsserver:3000

Причина:

zammad-railsserver стабильно отвечает HTTP 200, а внутренний zammad-nginx может зависать на ожидании init-состояния. Для Sprint 1 важнее поднять рабочий core runtime, чем отлаживать дополнительный внутренний nginx-слой Zammad.

Позже можно вернуть схему:

external nginx -> zammad-nginx -> zammad-railsserver
