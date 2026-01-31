#!/bin/bash
set -e

echo "MYSQL Master Setup Started---"

sudo apt update -y
sudo apt upgrade -y

sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

sudo systemctl start mysql
sudo systemctl enable mysql

sleep 10

# Configure MySQL for replication
cat >> /etc/mysql/mysql.conf.d/mysqld.cnf << EOF
[mysqld]
server-id=1
log-bin=/var/log/mysql/mysql-bin.log
binlog-do-db=${DB_NAME}
bind-address=0.0.0.0
EOF

sudo mkdir -p /var/log/mysql
sudo chown mysql:mysql /var/log/mysql

sudo systemctl restart mysql
sleep 15

# Secure MySQL installation and set root password
sudo mysql << MYSQL_SCRIPT
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Now configure replication and database
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" << MYSQL_SCRIPT
CREATE USER 'replicator'@'%' IDENTIFIED BY '${MYSQL_REPLICATION_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';

CREATE DATABASE IF NOT EXISTS ${DB_NAME};

CREATE USER 'appuser'@'%' IDENTIFIED BY '${MYSQL_APP_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO 'appuser'@'%';

FLUSH PRIVILEGES;

USE ${DB_NAME};

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email)
);

INSERT INTO users (name, email) VALUES
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Alice Johnson', 'alice@example.com');
MYSQL_SCRIPT

# Save master status
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW MASTER STATUS;" > /home/ubuntu/master-status.txt
sudo chown ubuntu:ubuntu /home/ubuntu/master-status.txt

echo "=== MySQL Master Setup Complete ==="
echo "Master status saved to: /home/ubuntu/master-status.txt"