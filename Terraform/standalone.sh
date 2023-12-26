#!/bin/bash

# Pre-configure debconf to set MySQL root password
export DEBIAN_FRONTEND=noninteractive

# Set MySQL root password (replace 'your_password' with your desired password)
MYSQL_ROOT_PASSWORD='root'

# Install MySQL Server without password prompt
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

# Update apt repositories
sudo apt-get update

# Install MySQL Server
sudo apt-get install -y mysql-server

# Check if MySQL service is running
sudo systemctl status mysql

echo "MySQL has been installed with root password: $MYSQL_ROOT_PASSWORD"