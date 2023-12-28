MASTER_DNS = "$1"
SLAVE_1 = "$2"
SLAVE_2 = "$3"
SLAVE_3 = "$4"

mkdir -p /opt/mysqlcluster/deploy
cd /opt/mysqlcluster/deploy
mkdir conf
mkdir mysql_data
mkdir ndb_data

cd conf
echo -e "[mysqld]\nndbcluster\ndatadir=/opt/mysqlcluster/deploy/mysqld_data\nbasedir=/opt/mysqlcluster/home/mysqlc\nport=3306" > my.cnf

cat <<EOF >config.ini
[ndb_mgmd]
# Management process options:
hostname=$MASTER  # Hostname of the manager
datadir=/opt/mysqlcluster/deploy/ndb_data
nodeid=1

[ndbd default]
noofreplicas=3
datadir=/opt/mysqlcluster/deploy/ndb_data

[ndbd]
hostname=$SLAVE_1
nodeid=3

[ndbd]
hostname=$SLAVE_2
nodeid=4

[ndbd]
hostname=$SLAVE_3  
nodeid=5

[mysqld]
nodeid=50
EOF

cat <<EOF >ndb_mgmd.service
[Unit]
Description=MySQL NDB Cluster Management Server
After=network.target auditd.service
[Service]
Type=forking
ExecStart=/usr/sbin/ndb_mgmd -f /var/lib/mysql-cluster/config.ini
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

sudo dos2unix config.ini
sudo cp config.ini /var/lib/mysql-cluster/

sudo systemctl daemon-reload 
sudo systemctl enable ndb_mgmd 
sudo systemctl start ndb_mgmd
sudo systemctl status ndb_mgmd