data "aws_route53_zone" "main" {
  name         = "nicholasjunge.com"
  private_zone = false
}

# ── CAA records — authorize Amazon to issue certificates ──────────────────────

resource "aws_route53_record" "caa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "nicholasjunge.com"
  type    = "CAA"
  ttl     = 300

  records = [
    "0 issue \"amazon.com\"",
    "0 issue \"amazontrust.com\"",
    "0 issuewild \"amazon.com\"",
    "0 issuewild \"amazontrust.com\"",
  ]
}

# ── ACM DNS validation records ────────────────────────────────────────────────
# The for_each key is the domain name, which naturally deduplicates the map —
# ACM returns the same CNAME for apex and www when they share a hosted zone.

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => dvo
  }

  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

# ── Apex A/AAAA alias records ─────────────────────────────────────────────────

resource "aws_route53_record" "apex_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "nicholasjunge.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "nicholasjunge.com"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# ── www A/AAAA alias records ──────────────────────────────────────────────────

resource "aws_route53_record" "www_a" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.nicholasjunge.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www.domain_name
    zone_id                = aws_cloudfront_distribution.www.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.nicholasjunge.com"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.www.domain_name
    zone_id                = aws_cloudfront_distribution.www.hosted_zone_id
    evaluate_target_health = false
  }
}
