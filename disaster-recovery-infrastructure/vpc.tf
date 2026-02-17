
# ==========================================
# PRIMARY REGION VPC - UPDATED
# ==========================================

resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = var.primary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "${var.project_name}-primary-vpc"
    Region = var.primary_region
  }
}

# Public Subnets - Primary
resource "aws_subnet" "primary_public_1" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-primary-public-1"
  }
}

resource "aws_subnet" "primary_public_2" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, 2)
  availability_zone       = data.aws_availability_zones.primary.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-primary-public-2"
  }
}

# Private Subnets - Primary (for RDS - need 2 for Multi-AZ)
resource "aws_subnet" "primary_private_1" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, 10)
  availability_zone       = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-primary-private-1"
  }
}

resource "aws_subnet" "primary_private_2" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, 11)
  availability_zone       = data.aws_availability_zones.primary.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-primary-private-2"
  }
}

# Internet Gateway - Primary
resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  tags = {
    Name = "${var.project_name}-primary-igw"
  }
}

# EIP for NAT Gateway
resource "aws_eip" "primary_nat" {
  provider = aws.primary
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-primary-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "primary" {
  provider      = aws.primary
  allocation_id = aws_eip.primary_nat.id
  subnet_id     = aws_subnet.primary_public_1.id

  tags = {
    Name = "${var.project_name}-primary-nat"
  }

  depends_on = [aws_internet_gateway.primary]
}

# Public Route Table
resource "aws_route_table" "primary_public" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }

  tags = {
    Name = "${var.project_name}-primary-public-rt"
  }
}

# Private Route Table
resource "aws_route_table" "primary_private" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary.id
  }

  tags = {
    Name = "${var.project_name}-primary-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "primary_public_1" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_public_1.id
  route_table_id = aws_route_table.primary_public.id
}

resource "aws_route_table_association" "primary_public_2" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_public_2.id
  route_table_id = aws_route_table.primary_public.id
}

resource "aws_route_table_association" "primary_private_1" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_private_1.id
  route_table_id = aws_route_table.primary_private.id
}

resource "aws_route_table_association" "primary_private_2" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_private_2.id
  route_table_id = aws_route_table.primary_private.id
}

# ==========================================
# SECONDARY REGION VPC - UPDATED
# ==========================================

resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = var.secondary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "${var.project_name}-secondary-vpc"
    Region = var.secondary_region
  }
}

# Public Subnets - Secondary
resource "aws_subnet" "secondary_public_1" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-secondary-public-1"
  }
}

resource "aws_subnet" "secondary_public_2" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, 2)
  availability_zone       = data.aws_availability_zones.secondary.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-secondary-public-2"
  }
}

# Private Subnets - Secondary (for RDS replica)
resource "aws_subnet" "secondary_private_1" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, 10)
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-secondary-private-1"
  }
}

resource "aws_subnet" "secondary_private_2" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, 11)
  availability_zone       = data.aws_availability_zones.secondary.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-secondary-private-2"
  }
}

# Internet Gateway - Secondary
resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  tags = {
    Name = "${var.project_name}-secondary-igw"
  }
}

# EIP for NAT Gateway
resource "aws_eip" "secondary_nat" {
  provider = aws.secondary
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-secondary-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "secondary" {
  provider      = aws.secondary
  allocation_id = aws_eip.secondary_nat.id
  subnet_id     = aws_subnet.secondary_public_1.id

  tags = {
    Name = "${var.project_name}-secondary-nat"
  }

  depends_on = [aws_internet_gateway.secondary]
}

# Public Route Table
resource "aws_route_table" "secondary_public" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary.id
  }

  tags = {
    Name = "${var.project_name}-secondary-public-rt"
  }
}

# Private Route Table
resource "aws_route_table" "secondary_private" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.secondary.id
  }

  tags = {
    Name = "${var.project_name}-secondary-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "secondary_public_1" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public_1.id
  route_table_id = aws_route_table.secondary_public.id
}

resource "aws_route_table_association" "secondary_public_2" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_public_2.id
  route_table_id = aws_route_table.secondary_public.id
}

resource "aws_route_table_association" "secondary_private_1" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_private_1.id
  route_table_id = aws_route_table.secondary_private.id
}

resource "aws_route_table_association" "secondary_private_2" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_private_2.id
  route_table_id = aws_route_table.secondary_private.id
}