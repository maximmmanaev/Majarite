# Runbook — Rollback Production

## Purpose

Rollback возвращает систему к предыдущему Git ref.

## Sprint 2 mode

В Sprint 2 rollback работает только в safe-plan режиме.

## Command

bash scripts/deploy/rollback.sh plan --to HEAD

## Rules

- rollback не должен удалять данные
- rollback не должен сам восстанавливать базу
- перед реальным rollback должен быть backup
- после rollback должен быть smoke-test

## Later

В следующих спринтах можно добавить:
- app/config rollback
- DB restore rollback
- tag-based rollback
