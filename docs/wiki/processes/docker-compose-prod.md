# Process — Docker Compose Production Override

## Назначение

compose.prod.yml содержит production-specific overrides для Majarite Core Runtime.

## Что делает файл

- Передает MAJARITE_ENV=prod в runtime-сервисы.
- Включает NODE_ENV=production для Node-RED.
- Добавляет shm_size для PostgreSQL-контейнеров.

## Что не делает файл

- Не хранит секреты.
- Не публикует PostgreSQL наружу.
- Не публикует Valkey наружу.
- Не добавляет AI, KB, MAX, Telegram или телефонию.

## Команда проверки

docker compose --env-file env/dev/.env.example -f infra/compose/compose.base.yml -f infra/compose/compose.core.yml -f infra/compose/compose.prod.yml config

## Связанные файлы

- infra/compose/compose.base.yml
- infra/compose/compose.core.yml
- infra/compose/compose.prod.yml
- env/prod/.env.example
