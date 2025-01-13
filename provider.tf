# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # This bucket must already exist. See pre requirements in README.md for the command to create it.
  backend "s3" {
    bucket = "terraform-wordpress-state"
    key = "wordpress"
  }

}

provider "aws" {
  region = var.aws_region
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}