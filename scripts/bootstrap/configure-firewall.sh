#!/usr/bin/env bash
set -Eeuo pipefail

echo "Configuring UFW firewall for Majarite Core Runtime"

sudo apt-get update
sudo apt-get install -y ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

echo "Planned UFW rules:"
sudo ufw status numbered || true

echo
echo "Firewall rules prepared."
echo "To enable firewall manually, run:"
echo "sudo ufw enable"
