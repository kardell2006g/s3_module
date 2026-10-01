---

# Terraform AWS S3 Bucket with KMS Encryption Module

This Terraform module provisions an AWS S3 bucket with a unique, workspace-based name, a KMS key for encryption, and an initial object. All resources are tagged for traceability and compliance. The module enforces explicit ACL configuration and sanitizes workspace names for AWS compatibility.

---

## Features

- **Globally unique S3 bucket name** based on sanitized Terraform workspace and random suffix
- **S3 object key** matches sanitized workspace name
- **KMS key** for default bucket and object encryption
- **Explicit, validated ACL** (no default, must be provided)
- **Tags** for workspace and email on all resources
- **Region** is configurable (default: `us-east-2`)
- **No owner tag** for compliance
- **Outputs** for bucket and object key

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.0 or later
- AWS credentials configured (via environment variables, shared credentials file, or IAM role)
- [AWS CLI](https://aws.amazon.com/cli/) (optional, for verification)

---

## Usage

```hcl
module "secure_s3_bucket" {
  source = "./" # or the path to your module

  email      = "your.email@company.com"
  bucket_acl = "private" # Must be one of the allowed ACLs (see below)
  # aws_region = "us-east-2" # Optional, override if needed
}
```

**Apply with:**
```sh
terraform init
terraform apply -var="email=your.email@company.com" -var="bucket_acl=private"
```

---

## Variables

| Name         | Description                                      | Type   | Default      | Required |
|--------------|--------------------------------------------------|--------|--------------|----------|
| aws_region   | AWS region to deploy resources                   | string | us-east-2    | No       |
| email        | The email to tag resources with                  | string | n/a          | Yes      |
| bucket_acl   | The canned ACL to apply to the S3 bucket         | string | n/a          | Yes      |

**Valid values for `bucket_acl`:**
- `private`
- `public-read`
- `public-read-write`
- `authenticated-read`
- `log-delivery-write`
- `bucket-owner-read`
- `bucket-owner-full-control`
- `aws-exec-read`

---

## Outputs

| Name         | Description                  |
|--------------|-----------------------------|
| bucket_name  | The name of the S3 bucket   |
| object_key   | The key of the S3 object    |

---

## Best Practices

- Always use a unique workspace per environment (e.g., `dev`, `stage`, `prod`).
- Never use public ACLs (`public-read`, `public-read-write`) unless absolutely required and approved by your security team.
- Use [Terraform Cloud](https://developer.hashicorp.com/terraform/cloud-docs) or [Terraform Enterprise](https://developer.hashicorp.com/terraform/enterprise) for governance, policy as code, and team collaboration.
- For advanced secrets management, integrate with [HashiCorp Vault](https://developer.hashicorp.com/vault/docs/secrets/aws).

---

## Security & Compliance

- All data at rest in S3 is encrypted with a customer-managed KMS key.
- Workspace names are sanitized to meet AWS naming requirements.
- Explicit ACL configuration is enforced for compliance.
