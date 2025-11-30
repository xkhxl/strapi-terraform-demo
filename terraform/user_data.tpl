#!/bin/bash
set -euo pipefail

# variables injected by terraform/templatefile:
# ${rds_endpoint}, ${db_password}, ${repo_url}, ${key_user}, ${REPO_DIR}, ${DOCKER_DIR}

apt-get update -y
apt-get install -y git curl apt-transport-https ca-certificates gnupg lsb-release ca-certificates

# install docker if missing
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
fi

# add key_user to docker group (if exists)
if id -u ${key_user} >/dev/null 2>&1; then
  usermod -aG docker ${key_user} || true
fi

# prepare repo directory (clone if missing)
REPO_DIR="${REPO_DIR}"
if [ ! -d "${REPO_DIR}" ]; then
  su - ${key_user} -c "git clone ${repo_url} ${REPO_DIR}" || true
fi

DOCKER_DIR="${DOCKER_DIR}"
if [ -d "${DOCKER_DIR}" ]; then
  cd "${DOCKER_DIR}"

  # ensure an .env exists (from example) and inject the real DB host/password
  cp .env.example .env || true

  sed -i "s|replace-with-rds-endpoint|${rds_endpoint}|g" .env || true
  sed -i "s|ChangeMe123!|${db_password}|g" .env || true

  # create local folder for Strapi data and set ownership
  mkdir -p ./strapi-data
  chown -R ${key_user}:${key_user} "${REPO_DIR}" || true
  chown -R ${key_user}:${key_user} ./strapi-data || true

  # download the Amazon RDS CA bundle to a known location
  RDS_CA_DIR="/home/${key_user}/rds-ca"
  mkdir -p "${RDS_CA_DIR}"
  curl -fsSL -o "${RDS_CA_DIR}/global-bundle.pem" https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem || true
  chown -R ${key_user}:${key_user} "${RDS_CA_DIR}" || true
  chmod 644 "${RDS_CA_DIR}/global-bundle.pem" || true

  # start docker compose (best-effort)
  /usr/bin/docker compose up -d || /usr/bin/docker-compose up -d || true
fi

exit 0
