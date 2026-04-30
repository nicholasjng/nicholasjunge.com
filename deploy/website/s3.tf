resource "aws_s3_bucket" "site" {
  bucket = "nicholasjunge.com"

  tags = {
    Site      = "nicholasjunge.com"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Bucket policy — allow both CloudFront distributions via OAC ───────────────

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = [
            aws_cloudfront_distribution.main.arn,
            aws_cloudfront_distribution.www.arn,
          ]
        }
      }
    }]
  })
}
