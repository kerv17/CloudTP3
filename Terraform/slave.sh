#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export PATH=/opt/mysqlcluster/home/mysqlc/bin:$PATH

sudo apt update && sudo apt install libaio1 libmecab2 libncurses5 dos2unix sysbench expect wget -y -qq

sudo mkdir -p /opt/mysqlcluster/home
cd /opt/mysqlcluster/home

sudo wget http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.2/mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz
sudo tar xvf mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz >/dev/null 2>&1 #Hush the output
sudo ln -s mysql-cluster-gpl-7.2.1-linux2.6-x86_64 mysqlc

echo 'export MYSQLC_HOME=/opt/mysqlcluster/home/mysqlc' | sudo tee /etc/profile.d/mysqlc.sh
echo 'export PATH=$MYSQLC_HOME/bin:$PATH' | sudo tee -a /etc/profile.d/mysqlc.sh

source /etc/profile.d/mysqlc.sh

sudo mkdir -p /opt/mysqlcluster/deploy/ndb_data
source /tmp/ips.sh

NODE_ID=""


if [ "$HOSTNAME" == "$SLAVE_1_DNS" ]; then
    NODE_ID=2
elif [ "$HOSTNAME" == "$SLAVE_2_DNS" ]; then
    NODE_ID=3
elif [ "$HOSTNAME" == "$SLAVE_3_DNS" ]; then
    NODE_ID=4
fi

sudo touch /opt/mysqlcluster/deploy/ndb_data/ndb_${NODE_ID}_out.log
sudo chown ubuntu:ubuntu /opt/mysqlcluster/deploy/ndb_data/ndb_${NODE_ID}_out.log

#Get the DNS of this instance
ndbd -c $MASTER_DNS:1186