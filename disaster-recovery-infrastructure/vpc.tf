# ==========================================
# PRIMARY REGION VPC
# ==========================================

resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = var.primary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-primary-vpc"
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
    Name = "${var.project_name}-primary-public-subnet-1"
  }
}

resource "aws_subnet" "primary_public_2" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, 2)
  availability_zone       = data.aws_availability_zones.primary.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-primary-public-subnet-2"
  }
}

# Private Subnet - Primary
resource "aws_subnet" "primary_private" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, 10)
  availability_zone       = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = true  # For easy SSH access during setup

  tags = {
    Name = "${var.project_name}-primary-private-subnet"
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

# Route Table - Primary
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

# Route Table Associations - Primary
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

resource "aws_route_table_association" "primary_private" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_private.id
  route_table_id = aws_route_table.primary_public.id
}

# ==========================================
# SECONDARY REGION VPC
# ==========================================

resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = var.secondary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-secondary-vpc"
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
    Name = "${var.project_name}-secondary-public-subnet-1"
  }
}

resource "aws_subnet" "secondary_public_2" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, 2)
  availability_zone       = data.aws_availability_zones.secondary.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-secondary-public-subnet-2"
  }
}

# Private Subnet - Secondary
resource "aws_subnet" "secondary_private" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = cidrsubnet(var.secondary_vpc_cidr, 8, 10)
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-secondary-private-subnet"
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

# Route Table - Secondary
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

# Route Table Associations - Secondary
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

resource "aws_route_table_association" "secondary_private" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_private.id
  route_table_id = aws_route_table.secondary_public.id
}

# Data sources for AZs
data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
  state    = "available"
}