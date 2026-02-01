# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "ubuntu_2204_primary" {
  provider    = aws.primary
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


data "aws_ami" "ubuntu_2204_secondary" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# ==========================================
# PRIMARY REGION INSTANCES
# ==========================================

# MySQL Master - Primary
resource "aws_instance" "primary_mysql_master" {
  provider               = aws.primary
  ami                    = data.aws_ami.ubuntu_2204_primary.id
  instance_type          = var.instance_type
  key_name               = var.key_name_primary
  subnet_id              = aws_subnet.primary_private.id
  vpc_security_group_ids = [aws_security_group.primary_db.id]

  user_data = templatefile("${path.module}/user-data/mysql-master.sh", {
    DB_NAME                    = var.db_name
    MYSQL_ROOT_PASSWORD        = var.mysql_root_password
    MYSQL_REPLICATION_PASSWORD = var.mysql_replication_password
    MYSQL_APP_PASSWORD         = var.mysql_app_password
  })

  tags = {
    Name = "${var.project_name}-primary-mysql-master"
    Role = "database-master"
  }

  # Ensure VPC peering is ready first
  depends_on = [aws_vpc_peering_connection_accepter.secondary, aws_nat_gateway.primary]
}

# Web Server - Primary
resource "aws_instance" "primary_web" {
  provider               = aws.primary
  ami                    = data.aws_ami.ubuntu_2204_primary.id
  instance_type          = var.instance_type
  key_name               = var.key_name_primary
  subnet_id              = aws_subnet.primary_public_1.id
  vpc_security_group_ids = [aws_security_group.primary_web.id]

  user_data = templatefile("${path.module}/user-data/web-primary.sh", {
    DB_HOST            = aws_instance.primary_mysql_master.private_ip
    DB_NAME            = var.db_name
    MYSQL_APP_PASSWORD = var.mysql_app_password
  })

  tags = {
    Name = "${var.project_name}-primary-web-server"
    Role = "web-server"
  }

  depends_on = [aws_instance.primary_mysql_master]
}

# ==========================================
# SECONDARY REGION INSTANCES
# ==========================================

# MySQL Slave - Secondary
resource "aws_instance" "secondary_mysql_slave" {
  provider               = aws.secondary
  ami                    = data.aws_ami.ubuntu_2204_secondary.id
  instance_type          = var.instance_type
  key_name               = var.key_name_secondary
  subnet_id              = aws_subnet.secondary_private.id
  vpc_security_group_ids = [aws_security_group.secondary_db.id]

  user_data = templatefile("${path.module}/user-data/mysql-slave.sh", {
    DB_NAME                    = var.db_name
    MYSQL_ROOT_PASSWORD        = var.mysql_root_password
    MYSQL_REPLICATION_PASSWORD = var.mysql_replication_password
    MASTER_HOST                = aws_instance.primary_mysql_master.private_ip
  })

  tags = {
    Name = "${var.project_name}-secondary-mysql-slave"
    Role = "database-slave"
  }

  depends_on = [
    aws_instance.primary_mysql_master,
    aws_vpc_peering_connection_accepter.secondary,
    aws_nat_gateway.secondary
  ]
}

# Web Server - Secondary
resource "aws_instance" "secondary_web" {
  provider               = aws.secondary
  ami                    = data.aws_ami.ubuntu_2204_secondary.id
  instance_type          = var.instance_type
  key_name               = var.key_name_secondary
  subnet_id              = aws_subnet.secondary_public_1.id
  vpc_security_group_ids = [aws_security_group.secondary_web.id]

  user_data = templatefile("${path.module}/user-data/web-secondary.sh", {
    DB_HOST            = aws_instance.secondary_mysql_slave.private_ip
    DB_NAME            = var.db_name
    MYSQL_APP_PASSWORD = var.mysql_app_password
  })

  tags = {
    Name = "${var.project_name}-secondary-web-server"
    Role = "web-server-dr"
  }

  depends_on = [aws_instance.secondary_mysql_slave]
}