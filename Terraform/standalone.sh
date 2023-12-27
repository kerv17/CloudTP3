#!/bin/bash

# Pre-configure debconf to set MySQL root password
export DEBIAN_FRONTEND=noninteractive

# Set MySQL root password (replace 'your_password' with your desired password)
MYSQL_ROOT_PASSWORD='root'

#Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections

# Install MySQL Server
sudo apt-get -y update
sudo apt-get -y install mysql-server

# Install sakila database
sudo apt-get -y install wget
wget https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xvzf sakila-db.tar.gz
cp -r sakila-db /tmp/

# Create sakila database
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE sakila;"

# Load data into sakila database
mysql -u root -p$MYSQL_ROOT_PASSWORD sakila < /tmp/sakila-db/sakila-schema.sql
mysql -u root -p$MYSQL_ROOT_PASSWORD sakila < /tmp/sakila-db/sakila-data.sql

# Install sysbench and git
sudo apt-get -y install sysbench git
git clone https://github.com/kerv17/CloudTP3.git

#Allow all users to execute every script in benchmarking folder
sudo chmod +x /home/ubuntu/CloudTP3/benchmarking/*.sh


