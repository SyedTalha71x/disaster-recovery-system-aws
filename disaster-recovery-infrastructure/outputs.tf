# ==========================================
# PRIMARY REGION OUTPUTS
# ==========================================

output "primary_vpc_id" {
  description = "Primary VPC ID"
  value       = aws_vpc.primary.id
}

output "primary_mysql_master_private_ip" {
  description = "Primary MySQL Master Private IP"
  value       = aws_instance.primary_mysql_master.private_ip
}

output "primary_mysql_master_public_ip" {
  description = "Primary MySQL Master Public IP"
  value       = aws_instance.primary_mysql_master.public_ip
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
# SECONDARY REGION OUTPUTS
# ==========================================

output "secondary_vpc_id" {
  description = "Secondary VPC ID"
  value       = aws_vpc.secondary.id
}

output "secondary_mysql_slave_private_ip" {
  description = "Secondary MySQL Slave Private IP"
  value       = aws_instance.secondary_mysql_slave.private_ip
}

output "secondary_mysql_slave_public_ip" {
  description = "Secondary MySQL Slave Public IP"
  value       = aws_instance.secondary_mysql_slave.public_ip
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
# S3 BUCKETS
# ==========================================

output "primary_s3_bucket_name" {
  description = "Primary S3 Bucket Name"
  value       = aws_s3_bucket.primary.id
}

output "secondary_s3_bucket_name" {
  description = "Secondary S3 Bucket Name"
  value       = aws_s3_bucket.secondary.id
}

# ==========================================
# SSH COMMANDS
# ==========================================

output "ssh_primary_mysql" {
  description = "SSH command for Primary MySQL"
  value       = "ssh -i ${var.key_name_primary}.pem ec2-user@${aws_instance.primary_mysql_master.public_ip}"
}

output "ssh_primary_web" {
  description = "SSH command for Primary Web Server"
  value       = "ssh -i ${var.key_name_primary}.pem ec2-user@${aws_instance.primary_web.public_ip}"
}

output "ssh_secondary_mysql" {
  description = "SSH command for Secondary MySQL"
  value       = "ssh -i ${var.key_name_secondary}.pem ec2-user@${aws_instance.secondary_mysql_slave.public_ip}"
}

output "ssh_secondary_web" {
  description = "SSH command for Secondary Web Server"
  value       = "ssh -i ${var.key_name_secondary}.pem ec2-user@${aws_instance.secondary_web.public_ip}"
}

# ==========================================
# DATABASE CONNECTION INFO
# ==========================================

output "database_connection_primary" {
  description = "Database connection string for Primary"
  value = {
    host     = aws_instance.primary_mysql_master.private_ip
    database = var.db_name
    username = "appuser"
    password = var.mysql_app_password
  }
  sensitive = true
}

output "database_connection_secondary" {
  description = "Database connection string for Secondary (Read-Only)"
  value = {
    host     = aws_instance.secondary_mysql_slave.private_ip
    database = var.db_name
    username = "appuser"
    password = var.mysql_app_password
  }
  sensitive = true
}

