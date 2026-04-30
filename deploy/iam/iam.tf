# ── GitHub OIDC identity provider ─────────────────────────────────────────────
# Allows GitHub Actions to obtain short-lived AWS credentials via OIDC federation.
# The thumbprint is still required by the API but AWS validates GitHub's certs via
# root CA for well-known providers — the value below is not used for verification.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = local.tags
}

# ── GitHub Actions IAM role ───────────────────────────────────────────────────
# Assumed by GitHub Actions via OIDC. Its only permission is to assume the
# deploy role, which Terraform then does via the assume_role block in providers.tf.

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    sid     = "AllowGitHubOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Scoped to pushes to master in the website repo only.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:nicholasjunge/nicholasjunge.com:ref:refs/heads/master"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "nicholasjunge-github-actions"
  description        = "Assumed by GitHub Actions via OIDC to trigger deployments"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "github_actions_assume_deploy" {
  name = "assume-deploy-role"
  role = aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeDeployRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name}"
      },
      {
        Sid    = "TerraformState"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${local.state_bucket_name}",
          "arn:aws:s3:::${local.state_bucket_name}/*",
        ]
      },
    ]
  })
}

# ── Deploy IAM role ───────────────────────────────────────────────────────────
# Trusted principals: humans from var.trusted_principal_arns (use account root
# for IAM Identity Center SSO, which issues dynamic role ARNs) + the
# github-actions role for CI.

data "aws_iam_policy_document" "deploy_assume" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = concat(var.trusted_principal_arns, [aws_iam_role.github_actions.arn])
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = local.role_name
  description        = "Least-privilege deployment role for ${local.domain} (managed by Terraform)"
  assume_role_policy = data.aws_iam_policy_document.deploy_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "deploy_permissions" {
  # ── Route 53 ──────────────────────────────────────────────────────────────
  # List/describe is needed globally to look up the zone by name.
  statement {
    sid    = "Route53List"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:GetChange",
    ]
    resources = ["*"]
  }

  # Record mutations are restricted to the nicholasjunge.com zone.
  statement {
    sid    = "Route53Zone"
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.main.zone_id}"]
  }

  # ── ACM ───────────────────────────────────────────────────────────────────
  # ACM ARNs are unknown until the certificate is created, so resource-level
  # restriction is not practical here.
  statement {
    sid    = "Acm"
    effect = "Allow"
    actions = [
      "acm:RequestCertificate",
      "acm:DescribeCertificate",
      "acm:DeleteCertificate",
      "acm:ListCertificates",
      "acm:AddTagsToCertificate",
      "acm:ListTagsForCertificate",
    ]
    resources = ["*"]
  }

  # ── S3 — website bucket (bucket-level) ────────────────────────────────────
  statement {
    sid    = "S3Bucket"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:ListBucket",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketCORS",
      "s3:GetBucketWebsite",
      "s3:GetBucketLogging",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketRequestPayment",
      "s3:GetReplicationConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetAccelerateConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketIntelligentTieringConfiguration",
      "s3:GetBucketNotification",
    ]
    resources = ["arn:aws:s3:::${local.domain}"]
  }

  # ── S3 — website bucket (object-level) ────────────────────────────────────
  statement {
    sid    = "S3Objects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
    ]
    resources = ["arn:aws:s3:::${local.domain}/*"]
  }

  # ── S3 — Terraform state bucket ───────────────────────────────────────────
  statement {
    sid    = "TerraformState"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${local.state_bucket_name}",
      "arn:aws:s3:::${local.state_bucket_name}/*",
    ]
  }

  # ── CloudFront ─────────────────────────────────────────────────────────────
  # CloudFront resources do not support resource-level ARN restrictions for
  # most control-plane actions per the AWS documentation.
  statement {
    sid    = "CloudFrontDistributions"
    effect = "Allow"
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:UpdateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:ListDistributions",
      "cloudfront:TagResource",
      "cloudfront:UntagResource",
      "cloudfront:ListTagsForResource",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudFrontOac"
    effect = "Allow"
    actions = [
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:GetOriginAccessControlConfig",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:ListOriginAccessControls",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudFrontFunctions"
    effect = "Allow"
    actions = [
      "cloudfront:CreateFunction",
      "cloudfront:UpdateFunction",
      "cloudfront:DeleteFunction",
      "cloudfront:GetFunction",
      "cloudfront:PublishFunction",
      "cloudfront:DescribeFunction",
      "cloudfront:ListFunctions",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "nicholasjunge-deploy-policy"
  role   = aws_iam_role.deploy.name
  policy = data.aws_iam_policy_document.deploy_permissions.json
}
