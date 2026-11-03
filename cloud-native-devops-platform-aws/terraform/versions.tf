terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state (recommended for teams). Create the S3 bucket + DynamoDB
  # table once, then uncomment this block and run `terraform init -migrate-state`.
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "devops-platform/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  # These tags are added to every resource Terraform creates
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
