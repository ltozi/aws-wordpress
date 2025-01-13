variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "eu-south-1" # Change this to your preferred region
}

variable "wordpress_version" {
  description = "WordPress Docker image version to use"
  type        = string
  default     = "latest"
}

variable "db_username" {
  description = "Master username for the RDS database"
  type        = string
  default     = "wordpress"
}

variable "db_password" {
  description = "Master password for the RDS database"
  type        = string
  sensitive   = true # This marks the variable as sensitive in logs and outputs
  default     = null
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # Smallest instance for cost optimization
}

variable "domain_name" {
description = "Domain name for the application (used for SSL certificate and CloudFront)"
type        = string
default     = null
}

variable "enable_http" {
description = "Whether to enable HTTP access (if false, only HTTPS will be allowed)"
type        = bool
default     = true
}
