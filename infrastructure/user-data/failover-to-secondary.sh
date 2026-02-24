#!/bin/bash

#  Disaster ke time manually chalana hoga ( guide only )
set -e

echo "=== Disaster Recovery Failover Started ==="

# 1. Promote MySQL slave to master
echo "Promoting MySQL slave to master..."
mysql -h secondary-db-host -u root -p"${MYSQL_ROOT_PASSWORD}" << EOF
STOP SLAVE;
RESET SLAVE ALL;
RESET MASTER;
SET GLOBAL read_only = OFF;

-- Create replication user for future failback
CREATE USER 'replicator_failback'@'%' IDENTIFIED BY '${MYSQL_REPLICATION_PASSWORD}';
GRANT REPLICATION SLAVE ON *.* TO 'replicator_failback'@'%';
FLUSH PRIVILEGES;
EOF

echo "MySQL promotion complete"

# 2. Update secondary web servers to use local database
echo "Updating web server configuration..."
# SSH to each secondary web server and update DB_HOST in .env file
# sed -i 's/DB_HOST=.*/DB_HOST=localhost/' /home/ubuntu/your-app/.env


echo "Restarting application..."
# pm2 restart all

# 4. Update DNS/Cloudflare (manual step with instructions)
echo ""
echo "=== MANUAL STEP REQUIRED ==="
echo "Please update your Cloudflare DNS:"
echo "1. Login to Cloudflare dashboard"
echo "2. Update your domain's A record to point to:"
echo "   - Secondary ALB DNS: $(terraform output -raw secondary_alb_dns_name)"
echo "3. Set TTL to 60 seconds"
echo ""
echo "Current secondary ALB DNS: $(terraform output -raw secondary_alb_dns_name)"
echo "=== Failover Script Complete ==="