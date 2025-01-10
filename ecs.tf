# ECS Cluster
resource "aws_ecs_cluster" "wordpress" {
  name = "wordpress-cluster"

  tags = {
    scope = "wordpress"
  }

  setting {
    name  = "containerInsights"
    value = "enhanced" #
  }
}

# IAM Role for ECS Tasks (for EFS access)
resource "aws_iam_role" "ecs_task_role" {
  name = "wordpress-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    scope = "terraform-worpress"
  }
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "wordpress-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = aws_efs_file_system.wordpress.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "wordpress-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    scope = "terraform-worpress"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  tags = {
    scope = "wordpress"
  }

  volume {
    name = "wordpress-data"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.wordpress.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        iam             = "ENABLED"
        access_point_id = aws_efs_access_point.wordpress.id
      }
    }
  }

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = "wordpress:latest"
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
        value = aws_db_instance.main.endpoint
      },
      {
        name  = "WORDPRESS_DB_USER"
        value = var.db_username
      },
      {
        name  = "WORDPRESS_DB_PASSWORD"
        value = var.db_password
      },
      {
        name  = "WORDPRESS_DB_NAME"
        value = "wordpress"
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
  name                   = "wordpress"
  cluster                = aws_ecs_cluster.wordpress.id
  task_definition        = aws_ecs_task_definition.wordpress.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  #   deployment_maximum_percent = 100
  #   deployment_minimum_healthy_percent = 0

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
    scope = "terraform-worpress"
  }
}

# EFS File System
resource "aws_efs_file_system" "wordpress" {
  creation_token = "wordpress"
  encrypted      = true

  tags = {
    scope = "wordpress"
  }

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

# EFS Access Point
resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.wordpress.id

  posix_user {
    gid = 33
    uid = 33
  }

  root_directory {
    path = "/wordpress"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "755"
    }
  }

  tags = {
    scope = "terraform-worpress"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "wordpress" {
  count           = length(aws_subnet.public)
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.efs.id]
}


# Add CloudWatch Log Group
resource "aws_cloudwatch_log_group" "wordpress" {
  name              = "/ecs/wordpress"
  retention_in_days = 1

  tags = {
    scope = "terraform-worpress"
  }
}



### Autoscaling policies
# First, define the autoscaling target
resource "aws_appautoscaling_target" "wordpress" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.wordpress.name}/${aws_ecs_service.wordpress.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based scaling policy
resource "aws_appautoscaling_policy" "wordpress_cpu" {
  name               = "wordpress-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.wordpress.resource_id
  scalable_dimension = aws_appautoscaling_target.wordpress.scalable_dimension
  service_namespace  = aws_appautoscaling_target.wordpress.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
