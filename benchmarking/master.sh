cd /home/ubuntu
wget https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xvzf sakila-db.tar.gz
cp -r sakila-db /tmp/


while ! mysqladmin ping --silent; do
    sleep 1
done

mysql -u root -e "CREATE DATABASE sakila;"
mysql -u root sakila < /tmp/sakila-db/sakila-schema.sql
mysql -u root sakila < /tmp/sakila-db/sakila-data.sql

sysbench --table-size=1000000 --db-driver=mysql --mysql-user=root --mysql-password=root --mysql-db=sakila --threads=1 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua prepare
sysbench --table-size=1000000 --db-driver=mysql --mysql-user=root --mysql-password=root --mysql-db=sakila --threads=1 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua run
sysbench --table-size=1000000 --db-driver=mysql --mysql-user=root --mysql-password=root --mysql-db=sakila --threads=1 --rand-type=uniform /usr/share/sysbench/oltp_read_only.lua cleanup