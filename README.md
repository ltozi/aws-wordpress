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
![Architecture Diagram]

Key Components:
- VPC with public and private subnets across multiple AZs
- ECS Fargate for container orchestration
- RDS MySQL database in Multi-AZ configuration
- EFS for WordPress media storage
- Application Load Balancer with SSL/TLS termination
- Security Groups for network access control
- IAM roles for service permissions

## Prerequisites
- AWS Account with administrative access
- Terraform (version >= 0.13)
- AWS CLI configured with appropriate credentials
- S3 storage bucket for terraform state

```shell
aws s3api create-bucket \
--bucket terraform-wordpress-state \
--region eu-south-1 \
--create-bucket-configuration LocationConstraint=eu-south-1
```

## Infrastructure Components

### VPC and Networking
- Region: eu-south-1 (Milan)
- Private subnets for ECS tasks and RDS
- Public subnets for ALB
- NAT Gateways for outbound internet access
- Internet Gateway for public access

### ECS Fargate Service
- Containerized WordPress application
- Auto-scaling capabilities
- Task definitions with resource allocation
- Service discovery integration
- Automated container health checks

### RDS MySQL Database
- Multi-AZ deployment for high availability
- Automated backups
- Encrypted storage
- Performance-optimized instance class
- Automated maintenance and patching

### EFS Storage
- Shared file system for WordPress media
- Automatic scaling
- Multi-AZ availability
- Performance mode: General Purpose

### Application Load Balancer
- SSL/TLS termination
- HTTP to HTTPS redirection
- Health checks configuration
- Path-based routing
- WebSocket support

### Security Groups and IAM Roles
- Principle of least privilege
- Separate security groups for each component
- IAM roles for ECS tasks and execution
- Managed policies for AWS services

## Deployment Instructions

1. Clone the repository:
```bash
git clone <repository-url>
cd aws-wordpress-terraform
```

2. Initialize Terraform:
```bash
terraform init
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
- Regular security patches through automated updates
- WAF integration available for additional security

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
