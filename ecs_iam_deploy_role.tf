resource "aws_iam_policy" "deploy" {
  name        = "wordpress-deploy-policy"
  path        = "/ci/"
  description = "Policy for WordPress deployments via GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECS Permissions
      {
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecr:*",
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/scope" = "terraform-wordpress"
          }
        }
      },
      # RDS Permissions
      {
        Effect = "Allow"
        Action = [
          "rds:*",
          "secretsmanager:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/scope" = "terraform-wordpress"
          }
        }
      },
      # VPC Permissions
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "vpc:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/scope" = "terraform-wordpress"
          }
        }
      },
      # ALB Permissions
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "acm:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/scope" = "terraform-wordpress"
          }
        }
      },
      # EFS Permissions
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/scope" = "terraform-wordpress"
          }
        }
      },
      # IAM Permissions
      {
        Effect = "Allow"
        Action = [
          "iam:*",
          "sts:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/scope" = "terraform-wordpress"
          }
        }
      },
      # S3 Permissions (for Terraform state)
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:HeadObject"
        ]
        Resource = [
          "arn:aws:s3:::*",
        ]
      },
      # CloudWatch Logs Permissions
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/scope" = "terraform-wordpress"
          }
        }
      },
      # Autoscaling Permissions
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/scope" = "terraform-wordpress"
          }
        }
      }
    ]
  })
}