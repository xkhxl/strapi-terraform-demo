#!/bin/bash

apt-get update -y
apt-get install -y git curl apt-transport-https ca-certificates gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
usermod -aG docker ubuntu || true
cd /home/ubuntu
su - ubuntu -c "git clone https://github.com/xkhxl/strapi-terraform-demo.git || true"
cd /home/ubuntu/strapi-terraform-demo/docker || exit 0
cp .env.example .env || true
/usr/bin/docker compose up -d || /usr/bin/docker-compose up -d || true