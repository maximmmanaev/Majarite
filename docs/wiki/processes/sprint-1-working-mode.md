# Process — Sprint 1 Working Mode

## Режим работы

Работа идет маленькими шагами.

1. Assistant дает один маленький шаг.
2. User выполняет команды в WSL.
3. Если все успешно — User пишет готово.
4. Если ошибка — User присылает текст ошибки.
5. Следующий шаг начинается только после успешного завершения текущего.

## Запрещено

- Переходить к следующему шагу при ошибке.
- Смешивать несколько крупных изменений в один commit.
- Добавлять реальные секреты в Git.
- Использовать Docker images с тегом latest.
- Публиковать PostgreSQL или Valkey наружу.
- Подключать AI, KB, MAX или телефонию в Sprint 1.

## Commit policy

Каждый commit должен быть маленьким и проверяемым.

Примеры:

- docs: add sprint 1 runtime process
- infra: add core compose skeleton
- infra: add env examples
- scripts: add bootstrap scripts
- make: add core runtime targets

## Основные файлы Sprint 1

- docs/sprints/sprint-1-core-runtime.md
- docs/architecture/majorite-system-architecture.md
- docs/product/mvp-scope.md
- docs/runbooks/deploy-production.md
