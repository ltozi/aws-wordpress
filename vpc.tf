# VPC and networking
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    scope = "terraform-wordpress"
  }
}


# Create public subnets in different AZs
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name  = "wordpress-public-${count.index + 1}"
    scope = "terraform-wordpress"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name  = "wordpress-igw"
    scope = "terraform-wordpress"
  }
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name  = "wordpress-public-rt"
    scope = "terraform-wordpress"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# Create private subnets for the database
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 30)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    scope = "terraform-wordpress"
  }
}

# Create DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "wordpress-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    scope = "terraform-wordpress"
  }
}