resource "aws_db_instance" "main" {
  identifier                          = "wordpress-db"
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 20
  db_name                             = "wordpress"
  username                            = var.db_username
  password                            = random_password.db_password.result
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  multi_az                            = true
  db_subnet_group_name                = aws_db_subnet_group.main.name
  vpc_security_group_ids              = [aws_security_group.rds.id]

  tags = {
    scope = "terraform-wordpress"
  }

  lifecycle {
    ignore_changes = [multi_az]
  }
}


# Create a random password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "wordpress_db" {
  name_prefix = "worpress-db-password-"
  tags = {
    scope = "terraform-wordpress"
  }
}

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret_version" "wordpress_db" {
  secret_id = aws_secretsmanager_secret.wordpress_db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}