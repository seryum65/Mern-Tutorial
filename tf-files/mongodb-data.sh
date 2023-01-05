#!/bin/bash

apt-get update -y
apt install wget curl gnupg2 -y software-properties-common apt-transport-https ca-certificates lsb-release
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc|gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb-6.gpg
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
dpkg -i ./libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
apt-get update -y
apt install mongodb-org -y
systemctl enable --now mongod
systemctl start mongod