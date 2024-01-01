#!/bin/bash

sudo apt update -y
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

source /tmp/ips.sh
DOCKER_IMAGE="docker.io/kerv17/cloudtp3-proxy:latest"
sudo docker pull $DOCKER_IMAGE

chmod 600 /home/ubuntu/vocker2.pem

sudo docker -e -e SLAVE_1_DNS=$SLAVE_1_DNS -e SLAVE_2_DNS=$SLAVE_2_DNS -e SLAVE_3_DNS=$SLAVE_3_DNS -e MASTER_DNS=$MASTER_DNS -v /home/ubuntu/vocker2.pem:/etc/proxy/vocker2.pem --name proxy -p 80:80 $DOCKER_IMAGE