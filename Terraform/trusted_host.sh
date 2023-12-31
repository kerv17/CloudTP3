#!/bin/bash

sudo apt update -y
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

source /tmp/ips.sh

sudo docker pull $DOCKER_IMAGE

chmod 600 /home/ubuntu/vocker2.pem

sudo docker -e TRUSTED_HOST_DNS=$PROXY_DNS -v /home/ubuntu/vocker2.pem:/etc/proxy/vocker2.pem --name gatekeeper -p 80:80 $DOCKER_IMAGE