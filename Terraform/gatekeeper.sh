#!/bin/bash

sudo apt update -y
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

source /tmp/ips.sh
DOCKER_IMAGE="docker.io/kerv17/cloudtp3-gatekeeper:latest"
sudo docker pull $DOCKER_IMAGE

chmod 600 /home/ubuntu/vocker2.pem

sudo docker -e SELF_DNS=$GATEKEEPER_DNS -e TARGET_DNS=$TRUSTED_HOST_DNS -v /home/ubuntu/vocker2.pem:/etc/proxy/vocker2.pem --name gatekeeper -p 80:80 $DOCKER_IMAGE