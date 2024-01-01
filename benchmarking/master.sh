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


#Create database and tables
/opt/mysqlcluster/home/mysqlc/bin/mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
/opt/mysqlcluster/home/mysqlc/bin/mysql -u root -e "CREATE DATABASE prod;"
/opt/mysqlcluster/home/mysqlc/bin/mysql -u root -e "
    USE prod;
    CREATE TABLE direct_table (id INT NOT NULL AUTO_INCREMENT, request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (id));"

/opt/mysqlcluster/home/mysqlc/bin/mysql -u root -e "
    USE prod;
    CREATE TABLE customized_table (id INT NOT NULL AUTO_INCREMENT, request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (id));"
/opt/mysqlcluster/home/mysqlc/bin/mysql -u root -e "
    USE prod;
    CREATE TABLE random_table (id INT NOT NULL AUTO_INCREMENT, request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (id))"
