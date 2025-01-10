resource "aws_db_instance" "main" {
  identifier                          = "wordpress-db"
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 20
  db_name                             = "wordpress"
  username                            = var.db_username
  password                            = var.db_password
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  multi_az                            = false
  db_subnet_group_name                = aws_db_subnet_group.main.name
  vpc_security_group_ids              = [aws_security_group.rds.id]

  tags = {
    scope = "terraform-worpress"
  }
}
