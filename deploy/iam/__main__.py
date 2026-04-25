"""
Pulumi program — IAM role for deploying nicholasjunge.com.

This is a SEPARATE stack from the main website stack. Deploy it once with
admin credentials, then use the output role ARN for all subsequent `pulumi up`
runs against the main stack.

Permissions are scoped as tightly as possible:
  - S3 actions are restricted to the nicholasjunge.com bucket.
  - Route 53 actions are restricted to the nicholasjunge.com hosted zone
    (resolved at deploy time via a data source lookup).
  - ACM and CloudFront do not support resource-level restrictions for most
    actions, so those statements use "*".

Usage:
    # One-time setup with admin credentials:
    pulumi stack init iam -C deploy/iam
    pulumi config set aws:region us-east-1 -C deploy/iam -s iam
    pulumi config set aws:profile admin -C deploy/iam -s iam
    pulumi config set trustedPrincipalArn arn:aws:iam::ACCOUNT:user/website -C deploy/iam -s iam
    pulumi up -C deploy/iam -s iam

    # Wire the output role ARN into the website stack:
    pulumi config set aws:assumeRole.roleArn <role_arn> -C deploy/website -s prod
"""

import json

import pulumi
import pulumi_aws as aws

DOMAIN = "nicholasjunge.com"
BUCKET_ARN = f"arn:aws:s3:::{DOMAIN}"
ROLE_NAME = "nicholasjunge-deploy"

config = pulumi.Config()

# ── Trusted principal ─────────────────────────────────────────────────────────
# Who is allowed to call sts:AssumeRole on this role.
# If left empty, falls back to allowing any principal in the current account
# (i.e. any IAM entity that has been separately granted sts:AssumeRole).

caller = aws.get_caller_identity()

trusted_arns = config.get_object("trustedPrincipalArn") or config.get("trustedPrincipalArn")
if not trusted_arns:
    raise ValueError(
        "trustedPrincipalArn must be set. "
        "Run: pulumi config set trustedPrincipalArn arn:aws:iam::ACCOUNT:root"
    )
# Accept either a single ARN string or a list of ARNs.
if isinstance(trusted_arns, str):
    trusted_arns = [trusted_arns]

# ── Route 53 hosted zone (pre-existing) ──────────────────────────────────────
# Needed to build a resource ARN for the zone-scoped Route 53 permissions.

zone = aws.route53.get_zone_output(name=DOMAIN, private_zone=False)
zone_arn = zone.zone_id.apply(lambda zid: f"arn:aws:route53:::hostedzone/{zid}")

# ── GitHub OIDC identity provider ────────────────────────────────────────────
# Allows GitHub Actions to obtain short-lived AWS credentials via OIDC federation.
# AWS validates GitHub's certs via root CA; the thumbprint is still required by
# the API but is not used for verification by AWS for well-known providers.

github_oidc = aws.iam.OpenIdConnectProvider(
    "github-oidc",
    url="https://token.actions.githubusercontent.com",
    client_id_list=["sts.amazonaws.com"],
    thumbprint_list=["6938fd4d98bab03faadb97b34396831e3780aea1"],
    tags={"Site": DOMAIN, "ManagedBy": "pulumi"},
)

# ── GitHub Actions IAM role ───────────────────────────────────────────────────
# Assumed by GitHub Actions via OIDC. Its only permission is to assume the
# deploy role, which Pulumi then does via aws:assumeRole.roleArn in the stack config.

deploy_role_arn = caller.account_id.apply(
    lambda aid: f"arn:aws:iam::{aid}:role/{ROLE_NAME}"
)

github_actions_role = aws.iam.Role(
    "github-actions-role",
    name="nicholasjunge-github-actions",
    description="Assumed by GitHub Actions via OIDC to trigger deployments",
    assume_role_policy=github_oidc.arn.apply(
        lambda arn: json.dumps({
            "Version": "2012-10-17",
            "Statement": [{
                "Sid": "AllowGitHubOIDC",
                "Effect": "Allow",
                "Principal": {"Federated": arn},
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition": {
                    "StringEquals": {
                        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    },
                    # Scoped to pushes to master in the website repo only
                    "StringLike": {
                        "token.actions.githubusercontent.com:sub":
                            "repo:nicholasjunge/nicholasjunge.com:ref:refs/heads/master",
                    },
                },
            }],
        })
    ),
    tags={"Site": DOMAIN, "ManagedBy": "pulumi"},
)

aws.iam.RolePolicy(
    "github-actions-policy",
    name="assume-deploy-role",
    role=github_actions_role.name,
    policy=deploy_role_arn.apply(lambda arn: json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Sid": "AssumeDeployRole",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": arn,
        }],
    })),
)

# ── Deploy IAM role ───────────────────────────────────────────────────────────
# Trusted principals: humans from config (use account root for IAM Identity
# Center SSO, which issues dynamic role ARNs) + the github-actions role for CI.

trust_policy = pulumi.Output.all(github_actions_role.arn).apply(
    lambda args: json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Sid": "AllowAssumeRole",
            "Effect": "Allow",
            "Principal": {"AWS": [*trusted_arns, args[0]]},
            "Action": "sts:AssumeRole",
        }],
    })
)

role = aws.iam.Role(
    "deploy-role",
    name=ROLE_NAME,
    description=f"Least-privilege deployment role for {DOMAIN} (managed by Pulumi)",
    assume_role_policy=trust_policy,
    tags={"Site": DOMAIN, "ManagedBy": "pulumi"},
)

# ── Permissions policy ────────────────────────────────────────────────────────

permissions = pulumi.Output.all(zone_arn=zone_arn).apply(
    lambda args: json.dumps(
        {
            "Version": "2012-10-17",
            "Statement": [
                # ── Route 53 ────────────────────────────────────────────────
                # List/describe is needed globally to look up the zone by name.
                {
                    "Sid": "Route53List",
                    "Effect": "Allow",
                    "Action": [
                        "route53:ListHostedZones",
                        "route53:ListHostedZonesByName",
                        "route53:GetChange",
                    ],
                    "Resource": "*",
                },
                # Record mutations are restricted to the nicholasjunge.com zone.
                {
                    "Sid": "Route53Zone",
                    "Effect": "Allow",
                    "Action": [
                        "route53:GetHostedZone",
                        "route53:ChangeResourceRecordSets",
                        "route53:ListResourceRecordSets",
                    ],
                    "Resource": args["zone_arn"],
                },
                # ── ACM ─────────────────────────────────────────────────────
                # ACM ARNs are unknown until the certificate is created, so
                # resource-level restriction is not practical here.
                {
                    "Sid": "Acm",
                    "Effect": "Allow",
                    "Action": [
                        "acm:RequestCertificate",
                        "acm:DescribeCertificate",
                        "acm:DeleteCertificate",
                        "acm:ListCertificates",
                        "acm:AddTagsToCertificate",
                        "acm:ListTagsForCertificate",
                    ],
                    "Resource": "*",
                },
                # ── S3 — bucket-level ────────────────────────────────────────
                {
                    "Sid": "S3Bucket",
                    "Effect": "Allow",
                    "Action": [
                        "s3:CreateBucket",
                        "s3:DeleteBucket",
                        "s3:ListBucket",
                        "s3:GetBucketLocation",
                        "s3:GetBucketPolicy",
                        "s3:PutBucketPolicy",
                        "s3:DeleteBucketPolicy",
                        "s3:GetBucketPublicAccessBlock",
                        "s3:PutBucketPublicAccessBlock",
                        "s3:GetBucketTagging",
                        "s3:PutBucketTagging",
                        # Pulumi reads these to detect drift
                        "s3:GetBucketVersioning",
                        "s3:GetBucketCORS",
                        "s3:GetBucketWebsite",
                        "s3:GetBucketLogging",
                        "s3:GetBucketObjectLockConfiguration",
                        "s3:GetBucketRequestPayment",
                        "s3:GetBucketReplication",
                        "s3:GetLifecycleConfiguration",
                        "s3:GetAccelerateConfiguration",
                    ],
                    "Resource": BUCKET_ARN,
                },
                # ── S3 — object-level ────────────────────────────────────────
                {
                    "Sid": "S3Objects",
                    "Effect": "Allow",
                    "Action": [
                        "s3:GetObject",
                        "s3:PutObject",
                        "s3:DeleteObject",
                        "s3:GetObjectTagging",
                        "s3:PutObjectTagging",
                    ],
                    "Resource": f"{BUCKET_ARN}/*",
                },
                # ── CloudFront ───────────────────────────────────────────────
                # CloudFront resources (distributions, OACs, functions) do not
                # support resource-level ARN restrictions for most control-plane
                # actions per the AWS documentation.
                {
                    "Sid": "CloudFrontDistributions",
                    "Effect": "Allow",
                    "Action": [
                        "cloudfront:CreateDistribution",
                        "cloudfront:GetDistribution",
                        "cloudfront:GetDistributionConfig",
                        "cloudfront:UpdateDistribution",
                        "cloudfront:DeleteDistribution",
                        "cloudfront:ListDistributions",
                        "cloudfront:TagResource",
                        "cloudfront:UntagResource",
                        "cloudfront:ListTagsForResource",
                    ],
                    "Resource": "*",
                },
                {
                    "Sid": "CloudFrontOac",
                    "Effect": "Allow",
                    "Action": [
                        "cloudfront:CreateOriginAccessControl",
                        "cloudfront:GetOriginAccessControl",
                        "cloudfront:GetOriginAccessControlConfig",
                        "cloudfront:UpdateOriginAccessControl",
                        "cloudfront:DeleteOriginAccessControl",
                        "cloudfront:ListOriginAccessControls",
                    ],
                    "Resource": "*",
                },
                {
                    "Sid": "CloudFrontFunctions",
                    "Effect": "Allow",
                    "Action": [
                        "cloudfront:CreateFunction",
                        "cloudfront:UpdateFunction",
                        "cloudfront:DeleteFunction",
                        "cloudfront:GetFunction",
                        "cloudfront:PublishFunction",
                        "cloudfront:DescribeFunction",
                        "cloudfront:ListFunctions",
                    ],
                    "Resource": "*",
                },
            ],
        }
    )
)

aws.iam.RolePolicy(
    "deploy-role-policy",
    name="nicholasjunge-deploy-policy",
    role=role.name,
    policy=permissions,
)

# ── Outputs ───────────────────────────────────────────────────────────────────

pulumi.export("role_arn", role.arn)
pulumi.export("role_name", role.name)
pulumi.export("github_actions_role_arn", github_actions_role.arn)
pulumi.export(
    "next_step",
    role.arn.apply(
        lambda arn: (
            f"Run in the deploy/ directory:\n"
            f"  pulumi config set aws:assumeRole.roleArn {arn} -C deploy/website -s prod"
        )
    ),
)
