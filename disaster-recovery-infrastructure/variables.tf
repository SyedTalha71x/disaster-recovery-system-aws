# variables.tf (Updated)
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "dr-system"
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

variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.small"
}

variable "key_name_primary" {
  description = "SSH key name for primary region"
  type        = string
}

variable "key_name_secondary" {
  description = "SSH key name for secondary region"
  type        = string
}

# RDS Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "myapp_db"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# S3 Variables
variable "s3_bucket_primary" {
  description = "Primary S3 bucket name"
  type        = string
}

variable "s3_bucket_secondary" {
  description = "Secondary S3 bucket name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your IP address for SSH access"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

