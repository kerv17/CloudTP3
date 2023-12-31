#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export PATH=/opt/mysqlcluster/home/mysqlc/bin:$PATH

sudo apt update && sudo apt install libaio1 libmecab2 git libncurses5 dos2unix sysbench expect wget -y

sudo mkdir -p /opt/mysqlcluster/home
cd /opt/mysqlcluster/home

sudo wget http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.2/mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz
sudo tar xvf mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz >/dev/null 2>&1 #Hush the output
sudo ln -s mysql-cluster-gpl-7.2.1-linux2.6-x86_64 mysqlc

echo 'export MYSQLC_HOME=/opt/mysqlcluster/home/mysqlc' | sudo tee /etc/profile.d/mysqlc.sh
echo 'export PATH=$MYSQLC_HOME/bin:$PATH' | sudo tee -a /etc/profile.d/mysqlc.sh

source /etc/profile.d/mysqlc.sh

sudo mkdir -p /opt/mysqlcluster/deploy
cd /opt/mysqlcluster/deploy
sudo mkdir conf mysqld_data ndb_data

cd conf

# Write the configuration to my.cnf
echo "[mysqld]
ndbcluster
datadir=/opt/mysqlcluster/deploy/mysqld_data
basedir=/opt/mysqlcluster/home/mysqlc
port=3306" | sudo tee /opt/mysqlcluster/deploy/conf/my.cnf > /dev/null

source /tmp/ips.sh

CONFIG_FILE="/opt/mysqlcluster/deploy/conf/config.ini"

echo "[ndbd_default]" | sudo tee $CONFIG_FILE > /dev/null
echo "hostname=$MASTER_DNS" | sudo tee -a $CONFIG_FILE > /dev/null
echo "datadir=/opt/mysqlcluster/deploy/ndb_data" | sudo tee -a $CONFIG_FILE > /dev/null
echo "nodeid=1" | sudo tee -a $CONFIG_FILE > /dev/null
echo "" | sudo tee -a $CONFIG_FILE > /dev/null

echo "[ndbd default]" | sudo tee -a $CONFIG_FILE > /dev/null
echo "noofreplicas=3" | sudo tee -a $CONFIG_FILE > /dev/null
echo "datadir=/opt/mysqlcluster/deploy/ndb_data" | sudo tee -a $CONFIG_FILE > /dev/null
echo "" | sudo tee -a $CONFIG_FILE > /dev/null

echo "[ndbd]" | sudo tee -a $CONFIG_FILE > /dev/null
echo "hostname=$SLAVE_1_DNS" | sudo tee -a $CONFIG_FILE > /dev/null
echo "nodeid=2" | sudo tee -a $CONFIG_FILE > /dev/null
echo "" | sudo tee -a $CONFIG_FILE > /dev/null

echo "[ndbd]" | sudo tee -a $CONFIG_FILE > /dev/null
echo "hostname=$SLAVE_2_DNS" | sudo tee -a $CONFIG_FILE > /dev/null
echo "nodeid=3" | sudo tee -a $CONFIG_FILE > /dev/null
echo "" | sudo tee -a $CONFIG_FILE > /dev/null

echo "[ndbd]" | sudo tee -a $CONFIG_FILE > /dev/null
echo "hostname=$SLAVE_3_DNS" | sudo tee -a $CONFIG_FILE > /dev/null
echo "nodeid=4" | sudo tee -a $CONFIG_FILE > /dev/null
echo "" | sudo tee -a $CONFIG_FILE > /dev/null

echo "[mysqld]" | sudo tee -a $CONFIG_FILE > /dev/null
echo "nodeid=50" | sudo tee -a $CONFIG_FILE > /dev/null

cd /opt/mysqlcluster/home/mysqlc
sudo scripts/mysql_install_db --no-defaults --datadir=/opt/mysqlcluster/deploy/mysqld_data
sudo chown -R root /opt/mysqlcluster/home/mysqlc
sudo /opt/mysqlcluster/home/mysqlc/bin/ndb_mgmd -f /opt/mysqlcluster/deploy/conf/config.ini --initial --configdir=/opt/mysqlcluster/deploy/conf/ --ndb-nodeid=1
sleep 120
sudo /opt/mysqlcluster/home/mysqlc/bin/ndb_mgm -e show

sudo mkdir -p /opt/mysqlcluster/deploy/mysqld_data
sudo chown -R root:root /opt/mysqlcluster/deploy/mysqld_data
sudo /opt/mysqlcluster/home/mysqlc/bin/mysqld --defaults-file=/opt/mysqlcluster/deploy/conf/my.cnf --user=root &


cd /home/ubuntu
wget https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xvzf sakila-db.tar.gz
cp -r sakila-db /tmp/

mysql -u root -e "CREATE DATABASE sakila;"
mysql -u root sakila < /tmp/sakila-db/sakila-schema.sql
mysql -u root sakila < /tmp/sakila-db/sakila-data.sql


# Install sysbench and git
cd /home/ubuntu
git clone https://github.com/kerv17/CloudTP3.git

#Allow all users to execute every script in benchmarking folder
sudo chmod +x /home/ubuntu/CloudTP3/benchmarking/*.sh