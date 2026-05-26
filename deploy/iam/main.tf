terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # No backend block — uses local state intentionally.
  # This stack is run once with admin credentials to bootstrap everything,
  # including the S3 bucket that the website stack uses as its backend.
  # State lives at deploy/iam/terraform.tfstate (gitignored).
}

provider "aws" {
  region = "us-east-1"
}

locals {
  domain            = "nicholasjunge.com"
  role_name         = "nicholasjunge-deploy"
  state_bucket_name = "nicholasjunge-terraform-state"
  tags = {
    Site      = "nicholasjunge.com"
    ManagedBy = "terraform"
  }
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "main" {
  name         = local.domain
  private_zone = false
}
