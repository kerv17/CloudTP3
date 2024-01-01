#!/bin/bash

sudo apt update -y
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker


DOCKER_IMAGE="docker.io/kerv17/cloudtp3-proxy:latest"
sudo docker pull $DOCKER_IMAGE

sleep 5m # Wait for the ips.sh file to be created
source /tmp/ips.sh
sudo docker run -e SELF_DNS=$PROXY_DNS -e SLAVE_1_DNS=$SLAVE_1_DNS -e SLAVE_2_DNS=$SLAVE_2_DNS -e SLAVE_3_DNS=$SLAVE_3_DNS -e MASTER_DNS=$MASTER_DNS -v /home/ubuntu/vockey2.pem:/etc/proxy/vockey.pem --name proxy --network host $DOCKER_IMAGE