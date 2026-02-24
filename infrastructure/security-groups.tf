# ==========================================
# PRIMARY REGION SECURITY GROUPS - FIXED
# ==========================================

# ALB Security Group - Primary (Define FIRST - no dependencies)
resource "aws_security_group" "primary_alb" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-alb-sg"
  description = "Security group for primary ALB"
  vpc_id      = aws_vpc.primary.id

  tags = {
    Name        = "${var.project_name}-primary-alb-sg"
    Environment = var.environment
    Region      = var.primary_region
    Component   = "alb"
  }
}

# ALB Ingress Rules (separate resource to avoid cycles)
resource "aws_security_group_rule" "primary_alb_ingress_http" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from anywhere"
  security_group_id = aws_security_group.primary_alb.id
}

resource "aws_security_group_rule" "primary_alb_ingress_https" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS from anywhere"
  security_group_id = aws_security_group.primary_alb.id
}

# ALB Egress Rules (use CIDR blocks instead of SG references)
resource "aws_security_group_rule" "primary_alb_egress_app" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
  description       = "To web servers on app port"
  security_group_id = aws_security_group.primary_alb.id
}

resource "aws_security_group_rule" "primary_alb_egress_http" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
  description       = "Health checks to web servers"
  security_group_id = aws_security_group.primary_alb.id
}

# Web Server Security Group - Primary
resource "aws_security_group" "primary_web" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-web-sg"
  description = "Security group for primary web servers"
  vpc_id      = aws_vpc.primary.id

  tags = {
    Name        = "${var.project_name}-primary-web-sg"
    Environment = var.environment
    Region      = var.primary_region
    Component   = "web"
  }
}

# Web Server Ingress Rules
resource "aws_security_group_rule" "primary_web_ingress_http" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
  description       = "HTTP from ALB and health checks"
  security_group_id = aws_security_group.primary_web.id
}

resource "aws_security_group_rule" "primary_web_ingress_https" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
  description       = "HTTPS from ALB"
  security_group_id = aws_security_group.primary_web.id
}

resource "aws_security_group_rule" "primary_web_ingress_app" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
  description       = "Node.js app from ALB and internal"
  security_group_id = aws_security_group.primary_web.id
}

resource "aws_security_group_rule" "primary_web_ingress_ssh" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ssh_cidr]
  description       = "SSH from bastion/admin IP"
  security_group_id = aws_security_group.primary_web.id
}

# Web Server Egress Rules - UPDATED FOR RDS
resource "aws_security_group_rule" "primary_web_egress_db" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
  description       = "MySQL to primary RDS"
  security_group_id = aws_security_group.primary_web.id
}

resource "aws_security_group_rule" "primary_web_egress_https" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS for external services"
  security_group_id = aws_security_group.primary_web.id
}

resource "aws_security_group_rule" "primary_web_egress_http" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP for package updates"
  security_group_id = aws_security_group.primary_web.id
}

# Database Security Group - Primary (UPDATED FOR RDS)
resource "aws_security_group" "primary_db" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-db-sg"
  description = "Security group for primary RDS MySQL database"
  vpc_id      = aws_vpc.primary.id

  tags = {
    Name        = "${var.project_name}-primary-db-sg"
    Environment = var.environment
    Region      = var.primary_region
    Component   = "database"
  }
}

# Database Ingress Rules - UPDATED FOR RDS (removed replication rules)
resource "aws_security_group_rule" "primary_db_ingress_mysql_web" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
  description       = "MySQL from web servers in primary"
  security_group_id = aws_security_group.primary_db.id
}

# REMOVED: primary_db_ingress_mysql_replication - RDS handles replication automatically

resource "aws_security_group_rule" "primary_db_ingress_ssh" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.primary_vpc_cidr]
  description       = "SSH from web servers for troubleshooting"
  security_group_id = aws_security_group.primary_db.id
}

# Database Egress Rules - UPDATED FOR RDS (removed replication rules)
resource "aws_security_group_rule" "primary_db_egress_https" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS for updates via NAT"
  security_group_id = aws_security_group.primary_db.id
}

# REMOVED: primary_db_egress_mysql_replication - RDS handles replication automatically

# ==========================================
# SECONDARY REGION SECURITY GROUPS - FIXED
# ==========================================

# ALB Security Group - Secondary
resource "aws_security_group" "secondary_alb" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-alb-sg"
  description = "Security group for secondary ALB"
  vpc_id      = aws_vpc.secondary.id

  tags = {
    Name        = "${var.project_name}-secondary-alb-sg"
    Environment = var.environment
    Region      = var.secondary_region
    Component   = "alb"
  }
}

# ALB Ingress Rules
resource "aws_security_group_rule" "secondary_alb_ingress_http" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from anywhere"
  security_group_id = aws_security_group.secondary_alb.id
}

resource "aws_security_group_rule" "secondary_alb_ingress_https" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS from anywhere"
  security_group_id = aws_security_group.secondary_alb.id
}

# ALB Egress Rules
resource "aws_security_group_rule" "secondary_alb_egress_app" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [var.secondary_vpc_cidr]
  description       = "To web servers on app port"
  security_group_id = aws_security_group.secondary_alb.id
}

resource "aws_security_group_rule" "secondary_alb_egress_http" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.secondary_vpc_cidr]
  description       = "Health checks to web servers"
  security_group_id = aws_security_group.secondary_alb.id
}

# Web Server Security Group - Secondary
resource "aws_security_group" "secondary_web" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-web-sg"
  description = "Security group for secondary web servers"
  vpc_id      = aws_vpc.secondary.id

  tags = {
    Name        = "${var.project_name}-secondary-web-sg"
    Environment = var.environment
    Region      = var.secondary_region
    Component   = "web"
  }
}

# Web Server Ingress Rules
resource "aws_security_group_rule" "secondary_web_ingress_http" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.secondary_vpc_cidr]
  description       = "HTTP from ALB"
  security_group_id = aws_security_group.secondary_web.id
}

resource "aws_security_group_rule" "secondary_web_ingress_https" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.secondary_vpc_cidr]
  description       = "HTTPS from ALB"
  security_group_id = aws_security_group.secondary_web.id
}

resource "aws_security_group_rule" "secondary_web_ingress_app" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [var.secondary_vpc_cidr]
  description       = "Node.js app from ALB"
  security_group_id = aws_security_group.secondary_web.id
}

resource "aws_security_group_rule" "secondary_web_ingress_ssh" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ssh_cidr]
  description       = "SSH from bastion/admin IP"
  security_group_id = aws_security_group.secondary_web.id
}

# Web Server Egress Rules - UPDATED FOR RDS
resource "aws_security_group_rule" "secondary_web_egress_db" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.secondary_vpc_cidr]
  description       = "MySQL to secondary RDS"
  security_group_id = aws_security_group.secondary_web.id
}

resource "aws_security_group_rule" "secondary_web_egress_https" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS for external services"
  security_group_id = aws_security_group.secondary_web.id
}

resource "aws_security_group_rule" "secondary_web_egress_http" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP for package updates"
  security_group_id = aws_security_group.secondary_web.id
}

# Database Security Group - Secondary (UPDATED FOR RDS)
resource "aws_security_group" "secondary_db" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-db-sg"
  description = "Security group for secondary RDS MySQL database"
  vpc_id      = aws_vpc.secondary.id

  tags = {
    Name        = "${var.project_name}-secondary-db-sg"
    Environment = var.environment
    Region      = var.secondary_region
    Component   = "database"
  }
}

# Database Ingress Rules - UPDATED FOR RDS (removed replication rules)
resource "aws_security_group_rule" "secondary_db_ingress_mysql_web" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.secondary_vpc_cidr]
  description       = "MySQL from web servers in secondary"
  security_group_id = aws_security_group.secondary_db.id
}

# REMOVED: secondary_db_ingress_mysql_replication - RDS handles replication automatically

resource "aws_security_group_rule" "secondary_db_ingress_ssh" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.secondary_vpc_cidr]
  description       = "SSH from web servers for troubleshooting"
  security_group_id = aws_security_group.secondary_db.id
}

# Database Egress Rules - UPDATED FOR RDS (removed replication rules)
resource "aws_security_group_rule" "secondary_db_egress_https" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS for updates via NAT"
  security_group_id = aws_security_group.secondary_db.id
}

# REMOVED: secondary_db_egress_mysql_replication - RDS handles replication automatically

# ==========================================
# ADDITIONAL COMMON EGRESS RULES
# ==========================================

# Common egress rules for NTP and DNS
resource "aws_security_group_rule" "primary_web_egress_ntp" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "NTP for time sync"
  security_group_id = aws_security_group.primary_web.id
}

resource "aws_security_group_rule" "primary_web_egress_dns" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "DNS queries"
  security_group_id = aws_security_group.primary_web.id
}

resource "aws_security_group_rule" "primary_db_egress_ntp" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "NTP via NAT"
  security_group_id = aws_security_group.primary_db.id
}

resource "aws_security_group_rule" "primary_db_egress_dns" {
  provider          = aws.primary
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "DNS via NAT"
  security_group_id = aws_security_group.primary_db.id
}

resource "aws_security_group_rule" "secondary_web_egress_ntp" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "NTP for time sync"
  security_group_id = aws_security_group.secondary_web.id
}

resource "aws_security_group_rule" "secondary_web_egress_dns" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "DNS queries"
  security_group_id = aws_security_group.secondary_web.id
}

resource "aws_security_group_rule" "secondary_db_egress_ntp" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "NTP via NAT"
  security_group_id = aws_security_group.secondary_db.id
}

resource "aws_security_group_rule" "secondary_db_egress_dns" {
  provider          = aws.secondary
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "DNS via NAT"
  security_group_id = aws_security_group.secondary_db.id
}