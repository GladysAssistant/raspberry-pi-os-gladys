#!/bin/bash -e

curl -fsSL https://get.docker.com | sh
usermod -aG docker pi
systemctl enable docker
