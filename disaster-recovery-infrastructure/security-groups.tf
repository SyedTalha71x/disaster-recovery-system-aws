# ==========================================
# PRIMARY REGION SECURITY GROUPS - FIXED
# ==========================================

# Web Server Security Group - Primary (Public Subnet)
resource "aws_security_group" "primary_web" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-web-sg"
  description = "Security group for primary web servers in public subnet"
  vpc_id      = aws_vpc.primary.id

  # HTTP from ALB only
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_alb.id]
    description     = "HTTP from ALB Only"
  }

  # HTTPS from ALB only
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_alb.id]
    description     = "HTTPS from ALB Only"
  }

  # Application port from ALB only
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_alb.id]
    description     = "Node.js app from ALB"
  }

  # SSH from your IP only (direct to public subnet)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from your IP"
  }

  # MySQL to primary database in private subnet
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_db.id]
    description     = "MySQL to primary DB"
  }

  # HTTPS for external API calls and package updates
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for external services"
  }

  # HTTP for package updates (if needed)
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for package updates"
  }

  # NTP for time synchronization
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP for time sync"
  }

  # DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  tags = {
    Name = "${var.project_name}-primary-web-sg"
  }
}

# Database Security Group - Primary (Private Subnet with NAT)
resource "aws_security_group" "primary_db" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-db-sg"
  description = "Security group for primary MySQL in private subnet"
  vpc_id      = aws_vpc.primary.id

  # MySQL from web servers in primary region
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_web.id]
    description     = "MySQL from primary web servers"
  }

  # MySQL from secondary region for replication via VPC peering
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
    description = "MySQL replication from secondary region"
  }

  # SSH from web servers ONLY for emergency troubleshooting
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_web.id]
    description     = "SSH from web servers for troubleshooting"
  }

  # MySQL replication to secondary region
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
    description = "MySQL replication to secondary region"
  }

  # HTTPS for package updates and AWS services via NAT
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for updates via NAT"
  }

  # NTP via NAT
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP via NAT"
  }

  # DNS via NAT
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS via NAT"
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

  # HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  # Health check from AWS internal
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
    description = "Health checks from AWS"
  }

  # Outbound to web servers on port 3000
  egress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_web.id]
    description     = "To web servers on app port"
  }

  # Health checks to web servers
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_web.id]
    description     = "Health checks to web servers"
  }

  tags = {
    Name = "${var.project_name}-primary-alb-sg"
  }
}

# ==========================================
# SECONDARY REGION SECURITY GROUPS - FIXED
# ==========================================

# Web Server Security Group - Secondary (Public Subnet)
resource "aws_security_group" "secondary_web" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-web-sg"
  description = "Security group for secondary web servers in public subnet"
  vpc_id      = aws_vpc.secondary.id

  # HTTP from ALB only
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_alb.id]
    description     = "HTTP from ALB"
  }

  # HTTPS from ALB only
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_alb.id]
    description     = "HTTPS from ALB"
  }

  # Application port from ALB only
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_alb.id]
    description     = "Node.js app from ALB"
  }

  # SSH from your IP only (direct to public subnet)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from your IP"
  }

  # MySQL to secondary database in private subnet
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_db.id]
    description     = "MySQL to secondary DB"
  }

  # HTTPS for external API calls and package updates
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for external services"
  }

  # HTTP for package updates
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for package updates"
  }

  # NTP for time synchronization
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP for time sync"
  }

  # DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  tags = {
    Name = "${var.project_name}-secondary-web-sg"
  }
}

# Database Security Group - Secondary (Private Subnet with NAT)
resource "aws_security_group" "secondary_db" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-db-sg"
  description = "Security group for secondary MySQL in private subnet"
  vpc_id      = aws_vpc.secondary.id

  # MySQL from web servers in secondary region
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_web.id]
    description     = "MySQL from secondary web servers"
  }

  # MySQL from primary region for replication via VPC peering
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
    description = "MySQL replication from primary region"
  }

  # SSH from web servers ONLY for emergency troubleshooting
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_web.id]
    description     = "SSH from web servers for troubleshooting"
  }

  # MySQL replication to primary region
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
    description = "MySQL replication to primary region"
  }

  # HTTPS for package updates and AWS services via NAT
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for updates via NAT"
  }

  # NTP via NAT
  egress {
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NTP via NAT"
  }

  # DNS via NAT
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS via NAT"
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

  # HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from anywhere"
  }

  # Health check from AWS internal
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
    description = "Health checks from AWS"
  }

  # Outbound to web servers on port 3000
  egress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_web.id]
    description     = "To web servers on app port"
  }

  # Health checks to web servers
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_web.id]
    description     = "Health checks to web servers"
  }

  tags = {
    Name = "${var.project_name}-secondary-alb-sg"
  }
}