# Process — Bootstrap Scripts

## Назначение

Bootstrap scripts подготавливают Ubuntu-среду для Majarite Core Runtime.

## scripts/bootstrap/install-docker.sh

Устанавливает Docker Engine и Docker Compose plugin.

### Что делает

- устанавливает ca-certificates, curl, gnupg
- добавляет официальный Docker apt repository
- устанавливает docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin
- добавляет текущего пользователя в docker group

### Важно

После добавления пользователя в docker group может потребоваться перелогиниться в WSL или сервер.

## scripts/bootstrap/configure-firewall.sh

Готовит UFW firewall rules для production-like сервера.

### Разрешает

- 22/tcp
- 80/tcp
- 443/tcp

### Не разрешает наружу

- PostgreSQL
- Valkey
- Node-RED direct port
- Zammad direct runtime ports

## Важное правило

В Sprint 1 на локальном WSL firewall script не запускаем без необходимости. Его задача — быть готовым для Ubuntu-сервера.
