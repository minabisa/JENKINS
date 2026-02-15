#!/bin/bash
set -e

# --- install docker on the EC2 host ---
apt-get update -y
apt-get install -y docker.io

systemctl enable docker
systemctl start docker

# --- build a custom Jenkins image that already contains terraform + ansible ---
cat > /tmp/Dockerfile <<'EOF'
FROM jenkins/jenkins:lts-jdk17

USER root

# Basic tools
RUN apt-get update -y && apt-get install -y \
    curl \
    unzip \
    git \
    openssh-client \
    python3 \
    python3-pip \
    ansible \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install Terraform (pinned version for stability)
ARG TF_VERSION=1.6.6
RUN curl -fsSL -o /tmp/terraform.zip \
    https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
  && unzip /tmp/terraform.zip -d /usr/local/bin \
  && rm -f /tmp/terraform.zip \
  && terraform -version

USER jenkins
EOF

docker build -t jenkins-lab:lts /tmp

# Persistent Jenkins data
docker volume create jenkins_home

# --- run Jenkins container ---
docker rm -f jenkins || true
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins-lab:lts
