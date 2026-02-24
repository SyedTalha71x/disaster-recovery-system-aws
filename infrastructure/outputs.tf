# ==========================================
# PRIMARY REGION OUTPUTS
# ==========================================

output "primary_vpc_id" {
  description = "Primary VPC ID"
  value       = aws_vpc.primary.id
}

output "primary_web_server_public_ip" {
  description = "Primary Web Server Public IP"
  value       = aws_instance.primary_web.public_ip
}

output "primary_web_server_private_ip" {
  description = "Primary Web Server Private IP"
  value       = aws_instance.primary_web.private_ip
}

output "primary_alb_dns_name" {
  description = "Primary ALB DNS Name"
  value       = aws_lb.primary.dns_name
}

output "primary_alb_url" {
  description = "Primary ALB URL"
  value       = "http://${aws_lb.primary.dns_name}"
}

# ==========================================
# PRIMARY REGION RDS OUTPUTS
# ==========================================

output "primary_db_endpoint" {
  description = "Primary RDS MySQL endpoint (read-write)"
  value       = aws_db_instance.primary.address
}

output "primary_db_port" {
  description = "Primary RDS MySQL port"
  value       = aws_db_instance.primary.port
}

output "primary_db_arn" {
  description = "Primary RDS ARN"
  value       = aws_db_instance.primary.arn
}

output "primary_db_resource_id" {
  description = "Primary RDS Resource ID"
  value       = aws_db_instance.primary.resource_id
}

# ==========================================
# SECONDARY REGION OUTPUTS
# ==========================================

output "secondary_vpc_id" {
  description = "Secondary VPC ID"
  value       = aws_vpc.secondary.id
}

output "secondary_web_server_public_ip" {
  description = "Secondary Web Server Public IP"
  value       = aws_instance.secondary_web.public_ip
}

output "secondary_web_server_private_ip" {
  description = "Secondary Web Server Private IP"
  value       = aws_instance.secondary_web.private_ip
}

output "secondary_alb_dns_name" {
  description = "Secondary ALB DNS Name"
  value       = aws_lb.secondary.dns_name
}

output "secondary_alb_url" {
  description = "Secondary ALB URL"
  value       = "http://${aws_lb.secondary.dns_name}"
}

# ==========================================
# SECONDARY REGION RDS OUTPUTS (READ REPLICA)
# ==========================================

output "secondary_db_endpoint" {
  description = "Secondary RDS MySQL endpoint (read-only replica)"
  value       = aws_db_instance.secondary.address
}

output "secondary_db_port" {
  description = "Secondary RDS MySQL port"
  value       = aws_db_instance.secondary.port
}

output "secondary_db_arn" {
  description = "Secondary RDS ARN"
  value       = aws_db_instance.secondary.arn
}

output "secondary_db_resource_id" {
  description = "Secondary RDS Resource ID"
  value       = aws_db_instance.secondary.resource_id
}

output "secondary_db_replication_lag" {
  description = "Replication lag in seconds (CloudWatch metric)"
  value       = "Monitor via CloudWatch: AWS/RDS > ReplicaLag > ${aws_db_instance.secondary.identifier}"
}

# ==========================================
# S3 BUCKETS OUTPUTS
# ==========================================

output "primary_s3_bucket_name" {
  description = "Primary S3 Bucket Name"
  value       = aws_s3_bucket.primary.id
}

output "primary_s3_bucket_arn" {
  description = "Primary S3 Bucket ARN"
  value       = aws_s3_bucket.primary.arn
}

output "secondary_s3_bucket_name" {
  description = "Secondary S3 Bucket Name"
  value       = aws_s3_bucket.secondary.id
}

output "secondary_s3_bucket_arn" {
  description = "Secondary S3 Bucket ARN"
  value       = aws_s3_bucket.secondary.arn
}

# ==========================================
# BACKUP S3 BUCKET OUTPUTS
# ==========================================

output "backup_s3_bucket_name" {
  description = "Backup S3 Bucket Name"
  value       = aws_s3_bucket.backup.id
}

output "backup_s3_bucket_arn" {
  description = "Backup S3 Bucket ARN"
  value       = aws_s3_bucket.backup.arn
}

# ==========================================
# DATABASE CONNECTION STRINGS (SENSITIVE)
# ==========================================

output "primary_db_connection_string" {
  description = "Primary database connection string (sensitive)"
  value = {
    host     = aws_db_instance.primary.address
    port     = aws_db_instance.primary.port
    database = var.db_name
    username = var.db_username
  }
  sensitive = true
}

output "secondary_db_connection_string" {
  description = "Secondary database connection string (read-only, sensitive)"
  value = {
    host     = aws_db_instance.secondary.address
    port     = aws_db_instance.secondary.port
    database = var.db_name
    username = var.db_username
    note     = "This is a read-only replica. For writes, use primary DB."
  }
  sensitive = true
}

# ==========================================
# SSH COMMANDS
# ==========================================

output "ssh_primary_web" {
  description = "SSH command for Primary Web Server"
  value       = "ssh -i ${var.key_name_primary}.pem ubuntu@${aws_instance.primary_web.public_ip}"
}

output "ssh_secondary_web" {
  description = "SSH command for Secondary Web Server"
  value       = "ssh -i ${var.key_name_secondary}.pem ubuntu@${aws_instance.secondary_web.public_ip}"
}

# ==========================================
# DNS AND FAILOVER INFORMATION
# ==========================================

output "cloudflare_dns_setup" {
  description = "Cloudflare DNS configuration for failover"
  value       = <<-EOT
    Configure Cloudflare with two A records:
    1. Primary: ${aws_lb.primary.dns_name} (proxied)
    2. Secondary: ${aws_lb.secondary.dns_name} (proxied, TTL 120)
    
    Setup Cloudflare Load Balancer with:
    - Origin pools for both regions
    - Health checks on /health endpoint
    - Failover: If primary fails, route to secondary
  EOT
}

# ==========================================
# FAILOVER INSTRUCTIONS
# ==========================================

output "failover_instructions" {
  description = "Step-by-step instructions for manual failover"
  value       = <<-EOT
    
    ============================================
    DISASTER RECOVERY - FAILOVER INSTRUCTIONS
    ============================================
    
    IF PRIMARY REGION (${var.primary_region}) FAILS:
    
    STEP 1: Promote Read Replica to Standalone
    -------------------------------------------
    aws rds promote-read-replica \
      --db-instance-identifier ${aws_db_instance.secondary.identifier} \
      --region ${var.secondary_region}
    
    This takes 2-3 minutes. The replica becomes a standalone writable DB.
    
    STEP 2: Update Web Servers Configuration
    -----------------------------------------
    SSH to secondary web server and update .env:
    
    ssh -i ${var.key_name_secondary}.pem ubuntu@${aws_instance.secondary_web.public_ip}
    
    Then edit /opt/app/.env:
    sudo vi /opt/app/.env
    
    Change:
    READ_ONLY=true  ->  READ_ONLY=false
    (No need to change DB_HOST as it already points to local replica)
    
    Restart app:
    pm2 restart all
    
    STEP 3: Update Cloudflare DNS
    ------------------------------
    In Cloudflare dashboard:
    - Set secondary pool as default
    - Update load balancer rules
    
    STEP 4: Verify Application
    ---------------------------
    Access your app at: http://${aws_lb.secondary.dns_name}
    
    ============================================
    MONITORING COMMANDS
    ============================================
    
    Check Replication Lag:
    aws cloudwatch get-metric-statistics \
      --namespace AWS/RDS \
      --metric-name ReplicaLag \
      --dimensions Name=DBInstanceIdentifier,Value=${aws_db_instance.secondary.identifier} \
      --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
      --period 300 \
      --statistics Average \
      --region ${var.secondary_region}
    
    Test Health Endpoints:
    curl http://${aws_lb.primary.dns_name}/health
    curl http://${aws_lb.secondary.dns_name}/health
    
  EOT
}

# ==========================================
# COST ESTIMATION
# ==========================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost (approximate)"
  value       = <<-EOT
    Estimated monthly costs (approximate):
    
    EC2 (t3.small × 2):          ~ $40
    RDS Primary (db.t3.micro):    ~ $15
    RDS Read Replica:              ~ $7.50
    NAT Gateways (×2):            ~ $64
    S3 Storage (per GB):          ~ $0.023/GB
    Data Transfer:                 Variable
    
    Total estimate: ~$130-150/month (excluding S3 storage)
    
    NOTE: Free tier may apply for first 12 months
  EOT
}

# ==========================================
# QUICK REFERENCE
# ==========================================

output "quick_reference" {
  description = "Quick reference card"
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════╗
    ║           DR SYSTEM - QUICK REFERENCE CARD               ║
    ╠══════════════════════════════════════════════════════════╣
    ║                                                          ║
    ║  PRIMARY REGION: ${var.primary_region}                            ║
    ║  PRIMARY ALB:    ${aws_lb.primary.dns_name} ║
    ║  PRIMARY DB:     ${aws_db_instance.primary.address} ║
    ║                                                          ║
    ║  SECONDARY REGION: ${var.secondary_region}                       ║
    ║  SECONDARY ALB:   ${aws_lb.secondary.dns_name} ║
    ║  SECONDARY DB:    ${aws_db_instance.secondary.address} ║
    ║                                                          ║
    ║  RPO: < 1 minute                                         ║
    ║  RTO: < 3 minutes                                        ║
    ║                                                          ║
    ╚══════════════════════════════════════════════════════════╝
    
  EOT
}