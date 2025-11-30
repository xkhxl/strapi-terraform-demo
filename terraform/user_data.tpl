#!/bin/bash
set -euo pipefail
apt-get update -y
apt-get install -y git curl apt-transport-https ca-certificates gnupg lsb-release

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
fi

if id -u ${key_user} >/dev/null 2>&1; then
  usermod -aG docker ${key_user} || true
fi

REPO_DIR="/home/${key_user}/strapi-terraform-demo"
if [ ! -d "${REPO_DIR}" ]; then
  su - ${key_user} -c "git clone ${repo_url} ${REPO_DIR}"
fi

DOCKER_DIR="${REPO_DIR}/docker"
if [ -d "${DOCKER_DIR}" ]; then
  cd "${DOCKER_DIR}"
  cp .env.example .env || true

  sed -i "s|replace-with-rds-endpoint|${rds_endpoint}|g" .env || true
  sed -i "s|ChangeMe123!|${db_password}|g" .env || true

  chown -R ${key_user}:${key_user} "${REPO_DIR}"

  mkdir -p ./strapi-data
  chown -R ${key_user}:${key_user} ./strapi-data

  /usr/bin/docker compose up -d || /usr/bin/docker-compose up -d || true
fi

exit 0