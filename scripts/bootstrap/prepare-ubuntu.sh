#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y git curl wget ca-certificates gnupg jq make ufw unzip nano
