# General Variables
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "disaster-recovery-system"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for DR"
  type        = string
  default     = "ap-south-1"
}

# Network Variables
variable "primary_vpc_cidr" {
  description = "CIDR block for primary VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "CIDR block for secondary VPC"
  type        = string
  default     = "10.1.0.0/16"
}

# Instance Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name_primary" {
  description = "SSH key name for primary region"
  type        = string
  default     = "primary-key"
}

variable "key_name_secondary" {
  description = "SSH key name for secondary region"
  type        = string
  default     = "secondary-key"
}

# Database Variables
variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "mysql_replication_password" {
  description = "MySQL replication user password"
  type        = string
  sensitive   = true
}

variable "mysql_app_password" {
  description = "MySQL application user password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "disaster-recovery=-db"
}

# S3 Variables
variable "s3_bucket_primary" {
  description = "Primary S3 bucket name (must be globally unique)"
  type        = string
}

variable "s3_bucket_secondary" {
  description = "Secondary S3 bucket name (must be globally unique)"
  type        = string
}

# Your IP for SSH access
variable "allowed_ssh_cidr" {
  description = "Your IP address for SSH access (format: x.x.x.x/32)"
  type        = string
}