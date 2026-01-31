#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=== MySQL Slave Setup Started (Ubuntu 22.04) ==="

sudo apt update -y
sudo apt upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

sudo systemctl start mysql
sudo systemctl enable mysql
sleep 10

if [ -z "${DB_NAME}" ] || [ -z "${MYSQL_ROOT_PASSWORD}" ] || [ -z "${MASTER_HOST}" ] || [ -z "${MYSQL_REPLICATION_PASSWORD}" ]; then
    echo "ERROR: Required environment variables are not set!"
    exit 1
fi

# Configure MySQL for replication
cat >> /etc/mysql/mysql.conf.d/mysqld.cnf << EOF
[mysqld]
server-id=2
relay-log=/var/log/mysql/mysql-relay-bin
log-bin=/var/log/mysql/mysql-bin.log
binlog-do-db=${DB_NAME}
read_only=1
bind-address=0.0.0.0
EOF

sudo mkdir -p /var/log/mysql
sudo chown mysql:mysql /var/log/mysql

sudo systemctl restart mysql
sleep 15

# Secure MySQL installation (similar to master)
sudo mysql << MYSQL_SCRIPT
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

sleep 30

# Create the same database on slave (optional but recommended)
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" << MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Get master log file and position dynamically
# In production, you would fetch this from the master status file/API
# For now, we'll use placeholders - you need to implement this based on your setup
MASTER_LOG_FILE="mysql-bin.000001"
MASTER_LOG_POS=4

echo "Attempting to connect to master at: ${MASTER_HOST}"

# Configure replication with error handling
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" << MYSQL_SCRIPT
STOP SLAVE;
RESET SLAVE ALL;

CHANGE MASTER TO
  MASTER_HOST='${MASTER_HOST}',
  MASTER_USER='replicator',
  MASTER_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
  MASTER_LOG_FILE='${MASTER_LOG_FILE}',
  MASTER_LOG_POS=${MASTER_LOG_POS};

START SLAVE;
MYSQL_SCRIPT

sleep 10

echo "Checking replication status..."
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW SLAVE STATUS\G" > /home/ubuntu/slave-status.txt

# Extract key status information
SLAVE_IO_RUNNING=$(grep "Slave_IO_Running:" /home/ubuntu/slave-status.txt | awk '{print $2}')
SLAVE_SQL_RUNNING=$(grep "Slave_SQL_Running:" /home/ubuntu/slave-status.txt | awk '{print $2}')

echo "Slave_IO_Running: ${SLAVE_IO_RUNNING}"
echo "Slave_SQL_Running: ${SLAVE_SQL_RUNNING}"

if [ "${SLAVE_IO_RUNNING}" = "Yes" ] && [ "${SLAVE_SQL_RUNNING}" = "Yes" ]; then
    echo "SUCCESS: MySQL replication is running properly!"
else
    echo "ERROR: MySQL replication is not running correctly."
    echo "Check /home/ubuntu/slave-status.txt for details."
    exit 1
fi

sudo chown ubuntu:ubuntu /home/ubuntu/slave-status.txt

echo "=== MySQL Slave Setup Complete ==="
echo "Check status: cat /home/ubuntu/slave-status.txt"
