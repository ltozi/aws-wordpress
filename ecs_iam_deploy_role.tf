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

# Create policy for ECS deployments
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
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeClusters"
        ]
        Resource = [
          "arn:aws:ecs:*:*:service/wordpress-cluster/wordpress",
          "arn:aws:ecs:*:*:task-definition/wordpress:*",
          "arn:aws:ecs:*:*:cluster/wordpress-cluster"
        ]
      },
      # IAM Permissions
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:GetRole",
          "iam:GetPolicy"
        ]
        Resource = [
          "arn:aws:iam::*:role/wordpress-task-role",
          "arn:aws:iam::*:role/wordpress-execution-role",
          "arn:aws:iam::*:policy/ci/wordpress-deploy-policy"
        ]
      },
      # S3 Permissions
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*"
        ]
      },
      # ACM Permissions
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate"
        ]
        Resource = [
          "arn:aws:acm:*:*:certificate/*"
        ]
      },
      # Secrets Manager Permissions
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:worpress-db-password-*"
        ]
      },
      # EFS Permissions
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeFileSystems"
        ]
        Resource = [
          "arn:aws:elasticfilesystem:*:*:file-system/*"
        ]
      },
      # CloudWatch Logs Permissions
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:*"
        ]
      },
      # EC2 Permissions
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcs"
        ]
        Resource = [
          "*"
        ]
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