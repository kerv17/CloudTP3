#!/bin/bash

sudo apt update -y
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker


DOCKER_IMAGE="docker.io/kerv17/cloudtp3-gatekeeper:latest"
sudo docker pull $DOCKER_IMAGE

sleep 5m # Wait for the ips.sh file to be created
source /tmp/ips.sh
sudo docker run -e SELF_DNS=$GATEKEEPER_DNS -e TARGET_DNS=$PROXY_DNS -v /home/ubuntu/vockey2.pem:/etc/proxy/vockey.pem --name gatekeeper --network host $DOCKER_IMAGE