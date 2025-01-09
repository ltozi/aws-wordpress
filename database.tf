resource "aws_db_instance" "main" {
  identifier          = "wordpress-db"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "wordpress"
  username            = var.db_username
  password            = var.db_password
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    scope = "claranet"
  }
}

# Create private subnets for the database
resource "aws_subnet" "private" {
  count             = 2
  vpc_id           = aws_vpc.main.id
  cidr_block       = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    scope = "claranet"
  }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "wordpress-db-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = {
    scope = "claranet"
  }
}

# Create DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "wordpress-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    scope = "claranet"
  }
}