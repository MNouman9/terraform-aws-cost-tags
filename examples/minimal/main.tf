terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = module.cost_tags.tags
  }
}

module "cost_tags" {
  source = "../../"

  org_name    = "acme"
  environment = "dev"
  project     = "myapp"
  team        = "backend-team"
  cost_center = "eng-001"
}
