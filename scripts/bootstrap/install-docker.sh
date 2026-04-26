#!/usr/bin/env bash
set -Eeuo pipefail

echo "Installing Docker Engine for Ubuntu"

if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed:"
  docker --version
else
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings

  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  . /etc/os-release

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if ! groups "$USER" | grep -q '\bdocker\b'; then
  echo "Adding current user to docker group"
  sudo usermod -aG docker "$USER"
  echo "You may need to log out and log in again for docker group permissions."
fi

echo "Docker install script completed"
docker --version || true
docker compose version || true
