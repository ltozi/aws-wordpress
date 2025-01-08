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
    value = "disabled" # Per risparmiare sui costi
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
      file_system_id = aws_efs_file_system.wordpress.id
    }
  }

  container_definitions = jsonencode([
    {
      name  = "wordpress"
      image = "wordpress:${var.wordpress_version}"

      environment = [
        #         {
        #           name  = "WORDPRESS_DB_HOST"
        #           value = aws_rds_cluster.main.endpoint
        #         },
        #         {
        #           name  = "WORDPRESS_DB_USER"
        #           value = var.db_username
        #         }
      ]

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          hostPort      = 80
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "wordpress-data"
          containerPath = "/var/www/html"
          readOnly      = false
        }
      ]
    }
  ])
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
