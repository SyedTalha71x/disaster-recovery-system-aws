#!/bin/bash
set -e

echo "MYSQL Master Setup Started---"

sudo apt update -y
sudo apt upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server awscli

sudo systemctl start mysql
sudo systemctl enable mysql

sleep 10

# 2. Configure MySQL for replication
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

# Save master status locally (backup ke liye)
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW MASTER STATUS;" > /home/ubuntu/master-status.txt
sudo chown ubuntu:ubuntu /home/ubuntu/master-status.txt

echo "Saving master status to AWS SSM Parameter Store..."

sleep 10

MASTER_STATUS=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW MASTER STATUS\G" 2>/dev/null)

for i in {1..5}; do
    if [ -n "$MASTER_STATUS" ] && echo "$MASTER_STATUS" | grep -q "File"; then
        break
    fi
    echo "Waiting for MySQL to be ready... ($i/5)"
    sleep 10
    MASTER_STATUS=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW MASTER STATUS\G" 2>/dev/null)
done

MASTER_LOG_FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}' | head -1)
MASTER_LOG_POS=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}' | head -1)

if [ -n "$MASTER_LOG_FILE" ] && [ -n "$MASTER_LOG_POS" ]; then
    if aws ssm put-parameter \
        --name "/disaster-recovery/mysql/master-log-file" \
        --value "$MASTER_LOG_FILE" \
        --type "String" \
        --overwrite 2>/dev/null; then
        echo "Master log file saved to SSM: $MASTER_LOG_FILE"
    else
        echo "Warning: Could not save to SSM (check IAM permissions)"
    fi
    
    if aws ssm put-parameter \
        --name "/disaster-recovery/mysql/master-log-pos" \
        --value "$MASTER_LOG_POS" \
        --type "String" \
        --overwrite 2>/dev/null; then
        echo "Master log position saved to SSM: $MASTER_LOG_POS"
    else
        echo "Warning: Could not save to SSM (check IAM permissions)"
    fi
    
    echo "SSM Parameters:"
    echo "  - /disaster-recovery/mysql/master-log-file = $MASTER_LOG_FILE"
    echo "  - /disaster-recovery/mysql/master-log-pos = $MASTER_LOG_POS"
else
    echo "ERROR: Could not get master status from MySQL"
    echo "Master status output:"
    echo "$MASTER_STATUS"
fi

echo "=== MySQL Master Setup Complete ==="
echo "Master status saved locally: /home/ubuntu/master-status.txt"
echo "Master status saved to SSM: /disaster-recovery/mysql/master-log-file"