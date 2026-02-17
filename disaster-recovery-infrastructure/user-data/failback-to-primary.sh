#!/bin/bash

# Recovery ke time manually chalana hoga jab primary DB wapas online aaye ( guide only )
set -e

echo "=== Failback to Primary Started ==="

# 1. Check primary database is restored and running
echo "Checking primary database..."
# Add health check for primary database

# 2. Set up replication from secondary (now master) to primary
echo "Configuring primary as slave..."
PRIMARY_DB_HOST="primary-db-host"
SECONDARY_DB_HOST="secondary-db-host"

# Get master status from secondary
MASTER_STATUS=$(mysql -h $SECONDARY_DB_HOST -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW MASTER STATUS\G")
MASTER_LOG_FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
MASTER_LOG_POS=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')

# Configure primary as slave
mysql -h $PRIMARY_DB_HOST -u root -p"${MYSQL_ROOT_PASSWORD}" << EOF
STOP SLAVE;
RESET SLAVE ALL;

CHANGE MASTER TO
  MASTER_HOST='${SECONDARY_DB_HOST}',
  MASTER_USER='replicator_failback',
  MASTER_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
  MASTER_LOG_FILE='${MASTER_LOG_FILE}',
  MASTER_LOG_POS=${MASTER_LOG_POS};

START SLAVE;
EOF

echo "Replication configured from secondary to primary"

# 3. Update primary web servers
echo "Updating primary web servers..."
# SSH and update .env files

# 4. Monitor replication
echo "Monitoring replication..."
sleep 10
mysql -h $PRIMARY_DB_HOST -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master"

# 5. DNS update instructions
echo ""
echo "=== MANUAL STEP REQUIRED ==="
echo "When replication is caught up (Seconds_Behind_Master = 0):"
echo "1. Update Cloudflare DNS to point back to primary ALB"
echo "2. Primary ALB DNS: $(terraform output -raw primary_alb_dns_name)"
echo ""
echo "=== Failback Script Complete ==="