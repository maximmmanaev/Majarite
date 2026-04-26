# Runbook — Deploy Production

## Purpose

Документ описывает безопасный deploy Majarite Core Runtime.

## Preconditions

- working branch чистый
- Docker установлен
- env файл создан
- secrets не лежат в Git
- backup выполнен перед deploy

## Commands

Проверить compose:

make prod-config

Запустить core runtime:

make prod-up-core

Проверить runtime:

make smoke-test

Посмотреть статус:

make prod-health

## Rules

- Не запускать raw docker compose.
- Использовать только Makefile commands.
- Перед production deploy делать backup.
- После deploy обязательно запускать smoke-test.
