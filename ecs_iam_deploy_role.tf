# Create IAM user for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "github-actions-wordpress"
  path = "/ci/"

  tags = {
    Description = "IAM user for GitHub Actions WordPress deployments"
    scope       = "terraform-wordpress"
  }
}

# Create access key for the IAM user
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# Create IAM role for the deployment
resource "aws_iam_role" "github_actions" {
  name = "github-actions-wordpress-deploy"
  path = "/ci/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.github_actions.arn
        }
      }
    ]
  })

  tags = {
    Description = "Role for GitHub Actions WordPress deployments"
    scope       = "terraform-wordpress"
  }
}

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

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "deploy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.deploy.arn
}

# Allow user to assume the role
resource "aws_iam_user_policy" "assume_role" {
  name = "assume-deploy-role"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Resource = aws_iam_role.github_actions.arn
      }
    ]
  })
}

# Output the access key information
output "github_actions_access_key" {
  value     = aws_iam_access_key.github_actions.id
  sensitive = false
}

output "github_actions_secret_key" {
  value     = aws_iam_access_key.github_actions.secret
  sensitive = true
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}