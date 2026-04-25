"""
Pulumi program — deploys nicholasjunge.com to AWS S3 + CloudFront with HTTPS.

Architecture:
  - S3 bucket (private)  ← CloudFront OAC → main distribution (nicholasjunge.com)
  - www distribution (www.nicholasjunge.com) → CloudFront Function → 301 to apex
  - ACM certificate covering both names (DNS-validated via Route 53)
  - Route 53 A/AAAA alias records for both apex and www

Prerequisites:
  - Route 53 hosted zone for nicholasjunge.com already exists
  - SvelteKit project built with adapter-static (output in ./build)
  - AWS credentials available (env vars, ~/.aws/credentials, or IAM role)

Usage:
    uv sync
    pulumi stack init prod -C deploy/website
    pulumi config set aws:region us-east-1 -C deploy/website -s prod
    pulumi up -C deploy/website -s prod
"""

import json
import mimetypes
from pathlib import Path

import pulumi
import pulumi_aws as aws

# ── Constants ─────────────────────────────────────────────────────────────────

DOMAIN = "nicholasjunge.com"
WWW_DOMAIN = f"www.{DOMAIN}"

config = pulumi.Config()
BUILD_DIR = Path(config.get("buildDir") or "../../build").resolve()

# ── Providers ─────────────────────────────────────────────────────────────────
# ACM certificates used by CloudFront must be provisioned in us-east-1,
# regardless of where the rest of the stack lives.
#
# Explicit provider instances do NOT inherit stack-level aws:profile / aws:region
# config automatically, so we forward them here.
aws_config = pulumi.Config("aws")

us_east_1 = aws.Provider(
    "us-east-1-provider",
    region="us-east-1",
    profile=aws_config.get("profile"),
)

# ── Route 53 hosted zone (pre-existing) ──────────────────────────────────────

zone = aws.route53.get_zone_output(name=DOMAIN, private_zone=False)

# ── CAA records — authorize Amazon to issue certificates ─────────────────────

aws.route53.Record(
    "caa",
    zone_id=zone.zone_id,
    name=DOMAIN,
    type="CAA",
    ttl=300,
    records=[
        '0 issue "amazon.com"',
        '0 issue "amazontrust.com"',
        '0 issuewild "amazon.com"',
        '0 issuewild "amazontrust.com"',
    ],
)

# ── ACM Certificate ───────────────────────────────────────────────────────────

cert = aws.acm.Certificate(
    "site-cert",
    domain_name=DOMAIN,
    subject_alternative_names=[WWW_DOMAIN],
    validation_method="DNS",
    opts=pulumi.ResourceOptions(provider=us_east_1),
)


def create_validation_records(dvos):
    """Create one Route 53 CNAME per unique validation record.

    ACM may return the same CNAME for both domain and www when they share a
    hosted zone, so we deduplicate by record name.
    """
    seen: set[str] = set()
    fqdns = []
    for i, dvo in enumerate(dvos):
        name = dvo["resource_record_name"]
        if name in seen:
            continue
        seen.add(name)
        record = aws.route53.Record(
            f"cert-validation-record-{i}",
            zone_id=zone.zone_id,
            name=name,
            type=dvo["resource_record_type"],
            records=[dvo["resource_record_value"]],
            ttl=60,
            allow_overwrite=True,
        )
        fqdns.append(record.fqdn)
    return fqdns


validation_fqdns = cert.domain_validation_options.apply(create_validation_records)  # ty: ignore[missing-argument]

cert_validation = aws.acm.CertificateValidation(
    "cert-validation",
    certificate_arn=cert.arn,
    validation_record_fqdns=validation_fqdns,
    opts=pulumi.ResourceOptions(provider=us_east_1),
)

# ── S3 bucket (private origin) ────────────────────────────────────────────────

bucket = aws.s3.BucketV2(
    "site-bucket",
    bucket=DOMAIN,
    tags={"Site": DOMAIN},
)

aws.s3.BucketPublicAccessBlock(
    "site-bucket-pab",
    bucket=bucket.id,
    block_public_acls=True,
    block_public_policy=True,
    ignore_public_acls=True,
    restrict_public_buckets=True,
)

# ── CloudFront Origin Access Control ─────────────────────────────────────────

oac = aws.cloudfront.OriginAccessControl(
    "site-oac",
    description=f"OAC for {DOMAIN}",
    origin_access_control_origin_type="s3",
    signing_behavior="always",
    signing_protocol="sigv4",
)

# ── CloudFront Function — www → apex redirect ─────────────────────────────────
# Runs at viewer-request; the origin is never reached for the www distribution.

redirect_fn = aws.cloudfront.Function(
    "www-redirect-fn",
    runtime="cloudfront-js-2.0",
    comment=f"301 redirect {WWW_DOMAIN} → {DOMAIN}",
    publish=True,
    code=f"""\
async function handler(event) {{
    return {{
        statusCode: 301,
        statusDescription: "Moved Permanently",
        headers: {{
            location: {{ value: "https://{DOMAIN}" + event.request.uri }},
        }},
    }};
}}
""",
)

# ── Main CloudFront distribution (nicholasjunge.com) ─────────────────────────

distribution = aws.cloudfront.Distribution(
    "site-distribution",
    comment=DOMAIN,
    aliases=[DOMAIN],
    enabled=True,
    is_ipv6_enabled=True,
    default_root_object="index.html",
    origins=[
        aws.cloudfront.DistributionOriginArgs(
            domain_name=bucket.bucket_regional_domain_name,
            origin_id="s3-origin",
            origin_access_control_id=oac.id,
        )
    ],
    default_cache_behavior=aws.cloudfront.DistributionDefaultCacheBehaviorArgs(
        target_origin_id="s3-origin",
        viewer_protocol_policy="redirect-to-https",
        allowed_methods=["GET", "HEAD", "OPTIONS"],
        cached_methods=["GET", "HEAD"],
        compress=True,
        # AWS managed "CachingOptimized" policy
        cache_policy_id="658327ea-f89d-4fab-a63d-7e88639e58f6",
    ),
    custom_error_responses=[
        # SvelteKit adapter-static: unknown paths return 403 from S3;
        # serve index.html so the client-side router can handle them.
        aws.cloudfront.DistributionCustomErrorResponseArgs(
            error_code=403,
            response_code=200,
            response_page_path="/index.html",
        ),
        # 404 from S3 also falls back to index.html; the SvelteKit client-side
        # router renders the 404 page and sets the correct HTTP status.
        aws.cloudfront.DistributionCustomErrorResponseArgs(
            error_code=404,
            response_code=200,
            response_page_path="/index.html",
        ),
    ],
    restrictions=aws.cloudfront.DistributionRestrictionsArgs(
        geo_restriction=aws.cloudfront.DistributionRestrictionsGeoRestrictionArgs(
            restriction_type="none",
        )
    ),
    viewer_certificate=aws.cloudfront.DistributionViewerCertificateArgs(
        acm_certificate_arn=cert_validation.certificate_arn,
        ssl_support_method="sni-only",
        minimum_protocol_version="TLSv1.2_2021",
    ),
    tags={"Site": DOMAIN},
)

# ── www CloudFront distribution (www.nicholasjunge.com) ──────────────────────
# The CloudFront Function intercepts every request before the origin is hit,
# so the S3 origin here is never actually reached.

www_distribution = aws.cloudfront.Distribution(
    "www-distribution",
    comment=WWW_DOMAIN,
    aliases=[WWW_DOMAIN],
    enabled=True,
    is_ipv6_enabled=True,
    origins=[
        aws.cloudfront.DistributionOriginArgs(
            domain_name=bucket.bucket_regional_domain_name,
            origin_id="s3-origin-www",
            origin_access_control_id=oac.id,
        )
    ],
    default_cache_behavior=aws.cloudfront.DistributionDefaultCacheBehaviorArgs(
        target_origin_id="s3-origin-www",
        viewer_protocol_policy="redirect-to-https",
        allowed_methods=["GET", "HEAD"],
        cached_methods=["GET", "HEAD"],
        compress=True,
        # AWS managed "CachingDisabled" policy — redirects shouldn't be cached
        # at the origin level (the function response is still cached by default)
        cache_policy_id="4135ea2d-6df8-44a3-9df3-4b5a84be39ad",
        function_associations=[
            aws.cloudfront.DistributionDefaultCacheBehaviorFunctionAssociationArgs(
                event_type="viewer-request",
                function_arn=redirect_fn.arn,
            )
        ],
    ),
    restrictions=aws.cloudfront.DistributionRestrictionsArgs(
        geo_restriction=aws.cloudfront.DistributionRestrictionsGeoRestrictionArgs(
            restriction_type="none",
        )
    ),
    viewer_certificate=aws.cloudfront.DistributionViewerCertificateArgs(
        acm_certificate_arn=cert_validation.certificate_arn,
        ssl_support_method="sni-only",
        minimum_protocol_version="TLSv1.2_2021",
    ),
    tags={"Site": WWW_DOMAIN},
)

# ── S3 bucket policy — allow both CloudFront distributions via OAC ────────────

aws.s3.BucketPolicy(
    "site-bucket-policy",
    bucket=bucket.id,
    policy=pulumi.Output.all(
        bucket.arn, distribution.arn, www_distribution.arn
    ).apply(
        lambda args: json.dumps(
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "AllowCloudFrontOAC",
                        "Effect": "Allow",
                        "Principal": {"Service": "cloudfront.amazonaws.com"},
                        "Action": "s3:GetObject",
                        "Resource": f"{args[0]}/*",
                        "Condition": {
                            "StringEquals": {
                                "AWS:SourceArn": [args[1], args[2]],
                            }
                        },
                    }
                ],
            }
        )
    ),
)

# ── Route 53 records ──────────────────────────────────────────────────────────

for record_type in ("A", "AAAA"):
    aws.route53.Record(
        f"apex-{record_type.lower()}",
        zone_id=zone.zone_id,
        name=DOMAIN,
        type=record_type,
        aliases=[
            aws.route53.RecordAliasArgs(
                name=distribution.domain_name,
                zone_id=distribution.hosted_zone_id,
                evaluate_target_health=False,
            )
        ],
    )

    aws.route53.Record(
        f"www-{record_type.lower()}",
        zone_id=zone.zone_id,
        name=WWW_DOMAIN,
        type=record_type,
        aliases=[
            aws.route53.RecordAliasArgs(
                name=www_distribution.domain_name,
                zone_id=www_distribution.hosted_zone_id,
                evaluate_target_health=False,
            )
        ],
    )

# ── Upload static files to S3 ─────────────────────────────────────────────────


def _cache_control(path: Path) -> str:
    """Return an appropriate Cache-Control header for a given file path.

    - HTML files: revalidate on every request (CloudFront respects this).
    - SvelteKit hashed assets under _app/: immutable for 1 year.
    - Everything else: 1 hour.
    """
    if path.suffix == ".html":
        return "public, max-age=0, must-revalidate"
    # SvelteKit places content-hashed JS/CSS under _app/
    if "_app" in path.parts:
        return "public, max-age=31536000, immutable"
    return "public, max-age=3600"


def upload_build(build_path: Path) -> None:
    if not build_path.exists():
        pulumi.log.warn(
            f"Build directory '{build_path}' does not exist — skipping file upload. "
            "Run 'npm run build' first."
        )
        return

    for file_path in sorted(build_path.rglob("*")):
        if not file_path.is_file():
            continue

        key = str(file_path.relative_to(build_path))
        content_type, _ = mimetypes.guess_type(str(file_path))

        # Sanitise the Pulumi resource name (must be unique and alphanumeric)
        resource_name = "file-" + key.replace("/", "--").replace(".", "-")

        aws.s3.BucketObjectv2(
            resource_name,
            bucket=bucket.id,
            key=key,
            source=pulumi.FileAsset(str(file_path)),
            content_type=content_type or "application/octet-stream",
            cache_control=_cache_control(file_path),
        )


upload_build(BUILD_DIR)

# ── Stack outputs ─────────────────────────────────────────────────────────────

pulumi.export("site_url", f"https://{DOMAIN}")
pulumi.export("bucket_name", bucket.id)
pulumi.export("cloudfront_id", distribution.id)
pulumi.export("cloudfront_domain", distribution.domain_name)
pulumi.export("www_cloudfront_id", www_distribution.id)
pulumi.export("certificate_arn", cert.arn)
