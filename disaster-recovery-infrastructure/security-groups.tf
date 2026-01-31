# ==========================================
# PRIMARY REGION SECURITY GROUPS
# ==========================================

# Web Server Security Group - Primary
resource "aws_security_group" "primary_web" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-web-sg"
  description = "Security group for primary web servers"
  vpc_id      = aws_vpc.primary.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  # Application port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Node.js app"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from your IP"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-primary-web-sg"
  }
}

# Database Security Group - Primary
resource "aws_security_group" "primary_db" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-db-sg"
  description = "Security group for primary MySQL"
  vpc_id      = aws_vpc.primary.id

  # MySQL from web servers
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_web.id]
    description     = "MySQL from web servers"
  }

  # MySQL from secondary region (replication)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
    description = "MySQL replication from secondary"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from your IP"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-primary-db-sg"
  }
}

# ALB Security Group - Primary
resource "aws_security_group" "primary_alb" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-alb-sg"
  description = "Security group for primary ALB"
  vpc_id      = aws_vpc.primary.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-primary-alb-sg"
  }
}

# ==========================================
# SECONDARY REGION SECURITY GROUPS
# ==========================================

# Web Server Security Group - Secondary
resource "aws_security_group" "secondary_web" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-web-sg"
  description = "Security group for secondary web servers"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-secondary-web-sg"
  }
}

# Database Security Group - Secondary
resource "aws_security_group" "secondary_db" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-db-sg"
  description = "Security group for secondary MySQL"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_web.id]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-secondary-db-sg"
  }
}

# ALB Security Group - Secondary
resource "aws_security_group" "secondary_alb" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-alb-sg"
  description = "Security group for secondary ALB"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-secondary-alb-sg"
  }
}