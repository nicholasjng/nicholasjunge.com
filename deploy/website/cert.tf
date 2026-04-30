# ── ACM Certificate ───────────────────────────────────────────────────────────
# Must be provisioned in us-east-1 for use with CloudFront.

resource "aws_acm_certificate" "cert" {
  provider = aws.us_east_1

  domain_name               = "nicholasjunge.com"
  subject_alternative_names = ["www.nicholasjunge.com"]
  validation_method         = "DNS"

  tags = {
    Site      = "nicholasjunge.com"
    ManagedBy = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
