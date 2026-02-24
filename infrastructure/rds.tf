data "aws_caller_identity" "current" {
  provider = aws.primary
}

# ==========================================
# PRIMARY REGION RDS - MASTER
# ==========================================

# DB Subnet Group - Primary
resource "aws_db_subnet_group" "primary" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-db-subnet"
  description = "DB subnet group for primary RDS"
  subnet_ids = [
    aws_subnet.primary_private_1.id,
    aws_subnet.primary_private_2.id
  ]

  tags = {
    Name = "${var.project_name}-primary-db-subnet"
  }
}

# Parameter Group - Primary (for MySQL optimizations)
resource "aws_db_parameter_group" "primary" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-mysql8-params"
  family      = "mysql8.0"
  description = "Custom parameter group for MySQL 8.0"

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }
}

# RDS MySQL Instance - Primary
resource "aws_db_instance" "primary" {
  provider = aws.primary

  identifier = "${var.project_name}-primary-mysql"

  # Engine
  engine         = "mysql"
  engine_version = "8.4.7"

  # Instance class and storage
  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.primary.name
  vpc_security_group_ids = [aws_security_group.primary_db.id]

  # Backup and replication settings
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Deletion protection
  deletion_protection       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-primary-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"


  tags = {
    Name        = "${var.project_name}-primary-mysql"
    Environment = var.environment
    Role        = "primary-database"
  }
}

# ==========================================
# SECONDARY REGION RDS - READ REPLICA
# ==========================================

# DB Subnet Group - Secondary
resource "aws_db_subnet_group" "secondary" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-db-subnet"
  description = "DB subnet group for secondary RDS"
  subnet_ids = [
    aws_subnet.secondary_private_1.id,
    aws_subnet.secondary_private_2.id
  ]

  tags = {
    Name = "${var.project_name}-secondary-db-subnet"
  }
}

# Parameter Group - Secondary (must match primary)
resource "aws_db_parameter_group" "secondary" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-mysql8-params"
  family      = "mysql8.0"
  description = "Custom parameter group for MySQL 8.0 (matches primary)"

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }
}

# Add this new resource to create a KMS key in the secondary region
resource "aws_kms_key" "secondary_rds" {
  provider                = aws.secondary
  description             = "KMS key for RDS encryption in secondary region"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "${var.project_name}-secondary-rds-key"
  }
}

# Also create an alias for easier reference
resource "aws_kms_alias" "secondary_rds" {
  provider      = aws.secondary
  name          = "alias/${var.project_name}-secondary-rds-key"
  target_key_id = aws_kms_key.secondary_rds.key_id
}

# RDS Read Replica - Secondary (updated with proper KMS key)
resource "aws_db_instance" "secondary" {
  provider = aws.secondary

  identifier = "${var.project_name}-secondary-mysql-replica"

  # Replica configuration
  replicate_source_db = aws_db_instance.primary.arn

  # Instance class and storage
  instance_class    = var.db_instance_class
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.secondary_rds.arn  # Use the created KMS key

  # Network
  db_subnet_group_name   = aws_db_subnet_group.secondary.name
  vpc_security_group_ids = [aws_security_group.secondary_db.id]

  # Deletion protection
  deletion_protection       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-secondary-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name        = "${var.project_name}-secondary-mysql"
    Environment = var.environment
    Role        = "read-replica"
  }

  # Ensure primary and KMS key are created first
  depends_on = [
    aws_db_instance.primary,
    aws_kms_key.secondary_rds
  ]
}