# ── Terraform state bucket ────────────────────────────────────────────────────
# Must be applied before the website stack can run `terraform init`.
# The website stack's backend is configured to point at this bucket.

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
