#!/usr/bin/env bash
set -euo pipefail

# Installs Docker + Compose plugin only. The backend and Flink repos each
# ship their own docker-compose.yml, deployed by their own CD workflow
# (SSH + docker compose up -d) — this script's job ends at "Docker is ready".

if command -v docker &>/dev/null; then
  exit 0
fi

apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

usermod -aG docker "$(logname)" || true
