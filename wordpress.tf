# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

}

provider "aws" {
  region = var.aws_region
}

# VPC and networking
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "claranet"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "wordpress" {
  name = "wordpress-cluster"

  tags = {
    scope : "claranet"
  }

  setting {
    name  = "containerInsights"
    value = "enhanced" #
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  tags = {
    scope : "claranet"
  }

  volume {
    name = "wordpress-data"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.wordpress.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        iam = "DISABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = "public.ecr.aws/docker/library/wordpress:latest"
    essential = true
    cpu       = 256
    memory    = 512
    #     entryPoint = ["sh", "-c"]
    #     command    = ["ls -la /var/www/html"]

    # Add logging configuration
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/wordpress"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "wordpress"
        "awslogs-create-group"  = "true"
      }
    }

    volumes = [{
      name = "wordpress-data"
      efsVolumeConfiguration = {
        fileSystemId = aws_efs_file_system.wordpress.id
      }
    }]

    mountPoints = [{
      sourceVolume  = "wordpress-data"
      containerPath = "/var/www/html"
      readOnly      = false
    }]

    environment = [
      {
        name  = "WORDPRESS_DB_HOST"
        value = "dummy-host" # Temporary value
      },
      {
        name  = "WORDPRESS_DB_USER"
        value = "dummy-user" # Temporary value
      },
      {
        name  = "WORDPRESS_DB_PASSWORD"
        value = "dummy-pass" # Temporary value
      },
      {
        name  = "WORDPRESS_DB_NAME"
        value = "wordpress" # Temporary value
      }
    ]
    portMappings = [{
      protocol      = "tcp"
      containerPort = 80
      hostPort      = 80
    }]
  }])
}


# ECS Service
resource "aws_ecs_service" "wordpress" {
  name            = "wordpress"
  cluster         = aws_ecs_cluster.wordpress.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  tags = {
    scope = "claranet"
  }
}

# Aurora Serverless
# resource "aws_rds_cluster" "main" {
#   cluster_identifier     = "wordpress-db"
#   engine                = "aurora-mysql"
#   engine_mode           = "serverless"
#   database_name         = "wordpress"
#   master_username       = var.db_username
#   master_password       = var.db_password
#   skip_final_snapshot   = true
#   tags = {
#     scope: "claranet"
#   }
#   scaling_configuration {
#     auto_pause               = true
#     max_capacity            = 2
#     min_capacity            = 1
#     seconds_until_auto_pause = 300
#   }
# }

# EFS File System
resource "aws_efs_file_system" "wordpress" {
  creation_token = "wordpress"

  tags = {
    scope : "claranet"
  }

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}


# Add CloudWatch Log Group
resource "aws_cloudwatch_log_group" "wordpress" {
  name              = "/ecs/wordpress"
  retention_in_days = 30

  tags = {
    scope = "claranet"
  }
}
