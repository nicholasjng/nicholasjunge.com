output "site_url" {
  value = "https://nicholasjunge.com"
}

output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.main.domain_name
}

output "www_cloudfront_id" {
  value = aws_cloudfront_distribution.www.id
}

output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
}
