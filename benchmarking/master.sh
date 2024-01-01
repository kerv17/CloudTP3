cd /home/ubuntu
sudo wget https://downloads.mysql.com/docs/sakila-db.tar.gz
sudo tar -xvzf sakila-db.tar.gz
sudo cp -r sakila-db /tmp/

source /etc/profile.d/mysqlc.sh
mysql -u root -e "CREATE DATABASE sakila;"
mysql -u root sakila < /tmp/sakila-db/sakila-schema.sql
mysql -u root sakila < /tmp/sakila-db/sakila-data.sql

sysbench --table-size=1000000 --db-driver=mysql --mysql-user=root --mysql-db=sakila --mysql-host=127.0.0.1 --mysql-port=3306 --threads=1 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua prepare
sysbench --table-size=1000000 --db-driver=mysql --mysql-user=root --mysql-db=sakila --mysql-host=127.0.0.1 --mysql-port=3306 --threads=1 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua run
sysbench --table-size=1000000 --db-driver=mysql --mysql-user=root --mysql-db=sakila --mysql-host=127.0.0.1 --mysql-port=3306 --threads=1 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua cleanup
