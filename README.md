# AWS WordPress Infrastructure with Terraform

## Introduction
This project provides Infrastructure as Code (IaC) for deploying a highly available, scalable WordPress installation on AWS using Terraform. It implements AWS best practices for running production-grade WordPress websites with containerized architecture.

### Key Benefits
- **High Availability**: Multi-AZ deployment with automatic failover
- **Scalability**: ECS Fargate for automatic container scaling
- **Security**: Private subnets, security groups, and SSL/TLS support
- **Performance**: Application Load Balancer and RDS optimized configuration
- **Reliability**: EFS for persistent storage and RDS for managed database

## Architecture Overview

![img.png](img.png)

Key Components:
- VPC with public and private subnets across multiple AZs
- ECS Fargate for container orchestration
- RDS MySQL database in Multi-AZ configuration
- EFS for WordPress media storage
- Application Load Balancer with SSL/TLS termination
- Security Groups for network access control

## Prerequisites
- AWS Account with administrative access.
- Terraform (version >= 1.10)
- AWS CLI configured with appropriate credentials
- S3 storage bucket for terraform state

## Deployment Instructions

1. Clone the repository and setup AWS credentials:
```bash
git clone <repository-url>
```

When you're in the terraform root module, run this to setup a bucket for terraform

Create and select your AWS profile and change the variable below before running the script

```shell
export AWS_PROFILE=${MY_AWS_PROFILE_NAME} 
export AWS_REGION=eu-south-1 # Choose another region if needed

BUCKET_NAME=terraform-wordpress-state-$(openssl rand -hex 2)

aws s3api create-bucket \
--bucket terraform-wordpress-state-$(openssl rand -hex 2) \
--region ${AWS_REGION} \
--create-bucket-configuration LocationConstraint=${AWS_REGION}

cat << EOF > "env/backend_s3_personal.hcl"
bucket = "$BUCKET_NAME"
key    = "wordpress"
region = "$AWS_REGION"
EOF
```


2. Initialize Terraform:

WARNING: Be sure the s3 bucket for terraform state is created! Check the file content before running init!

```bash
terraform init -backend-config="env/backend_s3_personal.hcl"
```

3. Configure variables:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

4. Review the execution plan:
```bash
terraform plan
```

5. Apply the infrastructure:
```bash
terraform apply
```

## Configuration Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS Region | eu-south-1 |
| `environment` | Environment name | development |
| `vpc_cidr` | VPC CIDR block | 10.0.0.0/16 |
| `db_instance_class` | RDS instance type | db.t3.medium |
| `wordpress_image` | WordPress container image | wordpress:latest |

## Security Considerations
- All sensitive data stored in AWS Secrets Manager
- Network traffic restricted by security groups
- Private subnets for database and application tier
- SSL/TLS encryption for data in transit


## Cost Considerations
- ECS Fargate: Pay for used resources only
- RDS: Costs vary based on instance size and storage
- EFS: Pay for storage used
- ALB: Hourly rate plus bandwidth
- NAT Gateway: Hourly rate plus data processing
- Consider reserved instances for RDS to reduce costs
- Enable auto-scaling policies to optimize resource usage

## Support
For issues and feature requests, please open an issue in the repository.

[Architecture Diagram]: path/to/architecture/diagram.png
