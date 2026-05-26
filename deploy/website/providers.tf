terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    # State bucket is created by deploy/iam — run that stack first.
    # No DynamoDB lock table: single sequential workflow, concurrency not a concern.
    bucket = "nicholasjunge-terraform-state"
    key    = "website/terraform.tfstate"
    region = "us-east-1"
  }
}

# Default provider. GHA assumes nicholasjunge-github-actions via OIDC (configured-aws-credentials
# step), then Terraform assumes nicholasjunge-deploy here.
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::506333259771:role/nicholasjunge-deploy"
  }
}

# Aliased provider pinned to us-east-1 for ACM certificates used by CloudFront.
# Both providers are currently us-east-1, but the alias makes the ACM requirement explicit
# and keeps it pinned if the default provider ever moves to a different region.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::506333259771:role/nicholasjunge-deploy"
  }
}
