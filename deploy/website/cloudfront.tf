# ── Origin Access Control ─────────────────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "nicholasjunge.com OAC"
  description                       = "OAC for nicholasjunge.com"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── CloudFront Function — www → apex redirect ─────────────────────────────────
# Runs at viewer-request; the S3 origin is never reached for the www distribution.

resource "aws_cloudfront_function" "www_redirect" {
  name    = "www-redirect"
  runtime = "cloudfront-js-2.0"
  comment = "301 redirect www.nicholasjunge.com → nicholasjunge.com"
  publish = true
  code    = file("${path.module}/functions/www-redirect.js")
}

# ── Main CloudFront distribution (nicholasjunge.com) ─────────────────────────

resource "aws_cloudfront_distribution" "main" {
  comment             = "nicholasjunge.com"
  aliases             = ["nicholasjunge.com"]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    # AWS managed CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # SvelteKit adapter-static: unknown paths return 403 from S3;
  # serve index.html so the client-side router can handle them.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  # 404 from S3 also falls back to index.html; the SvelteKit client-side
  # router renders the 404 page and sets the correct HTTP status.
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Site      = "nicholasjunge.com"
    ManagedBy = "terraform"
  }
}

# ── www CloudFront distribution (www.nicholasjunge.com) ──────────────────────
# The CloudFront Function intercepts every request before the origin is hit,
# so the S3 origin here is never actually reached.

resource "aws_cloudfront_distribution" "www" {
  comment         = "www.nicholasjunge.com"
  aliases         = ["www.nicholasjunge.com"]
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-origin-www"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin-www"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    # AWS managed CachingDisabled policy — redirects shouldn't be cached at the
    # origin level (the function response is still cached by default)
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www_redirect.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Site      = "www.nicholasjunge.com"
    ManagedBy = "terraform"
  }
}
