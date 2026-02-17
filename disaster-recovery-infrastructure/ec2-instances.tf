
# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu_primary" {
  provider    = aws.primary
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_ami" "ubuntu_secondary" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Web Server - Primary
resource "aws_instance" "primary_web" {
  provider               = aws.primary
  ami                    = data.aws_ami.ubuntu_primary.id
  instance_type          = var.instance_type
  key_name               = var.key_name_primary
  subnet_id              = aws_subnet.primary_public_1.id
  vpc_security_group_ids = [aws_security_group.primary_web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/user-data/web-server.sh", {
    DB_HOST     = aws_db_instance.primary.address
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    REGION      = var.primary_region
    ROLE        = "primary"
  })

  tags = {
    Name = "${var.project_name}-primary-web"
    Role = "web-server"
  }
}

# Web Server - Secondary
resource "aws_instance" "secondary_web" {
  provider               = aws.secondary
  ami                    = data.aws_ami.ubuntu_secondary.id
  instance_type          = var.instance_type
  key_name               = var.key_name_secondary
  subnet_id              = aws_subnet.secondary_public_1.id
  vpc_security_group_ids = [aws_security_group.secondary_web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/user-data/web-server.sh", {
    DB_HOST     = aws_db_instance.secondary.address  # Read replica endpoint
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    REGION      = var.secondary_region
    ROLE        = "secondary"
  })

  tags = {
    Name = "${var.project_name}-secondary-web"
    Role = "web-server-dr"
  }
}