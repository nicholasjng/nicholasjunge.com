variable "trusted_principal_arns" {
  type        = list(string)
  description = "IAM principal ARNs allowed to assume the deploy role (in addition to the GitHub Actions role). Use the account root ARN for IAM Identity Center SSO, which issues dynamic role ARNs."
}
