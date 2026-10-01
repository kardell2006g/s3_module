---

# S3 Module

A reusable Terraform module for creating secure, compliant AWS S3 buckets with KMS encryption, CloudTrail logging, lifecycle management, and enterprise security controls.

---

## Features

- **Globally unique S3 bucket name** based on sanitized Terraform workspace and random suffix
- **KMS key** for default bucket and object encryption
- **CloudTrail integration** for S3 object-level logging
- **Lifecycle management** for automatic object expiration
- **Public access block** and SSL-only enforcement
- **Object Ownership controls** (recommended: `BucketOwnerEnforced`)
- **Versioning** with MFA Delete (manual step required)
- **Tagging** for workspace and email
- **Outputs** for bucket, CloudTrail, KMS, and compliance reminders

---

## Usage

```hcl
module "secure_s3_bucket" {
  source = "github.com/kardell2006g/s3_module"

  aws_region              = "us-east-2"
  email                   = "your.email@company.com"
  target_expiration_days  = 30
  # Optionally override other variables as needed
}
```

---

## Variables

| Name                   | Description                                      | Type    | Default      | Required |
|------------------------|--------------------------------------------------|---------|--------------|----------|
| aws_region             | AWS region to deploy resources                   | string  | us-east-2    | No       |
| email                  | The email to tag resources with                  | string  | n/a          | Yes      |
| target_expiration_days | Days after which objects expire                  | number  | 30           | No       |

---

## Outputs

| Name                    | Description                                                      |
|-------------------------|------------------------------------------------------------------|
| bucket_name             | The name of the S3 bucket                                        |
| kms_key_arn             | The ARN of the KMS key used for S3 bucket encryption             |
| kms_key_id              | The ID of the KMS key used for S3 bucket encryption              |
| cloudtrail_log_bucket   | The S3 bucket where CloudTrail logs are delivered                |
| cloudtrail_arn          | The ARN of the CloudTrail trail                                  |
| mfa_delete_manual_step  | Manual step required to enable MFA Delete on the S3 bucket       |

---

## Security & Compliance

- **Block Public Access:** All public ACLs and policies are blocked.
- **SSL Enforcement:** All requests to the bucket must use SSL.
- **KMS Encryption:** All objects are encrypted with a customer-managed KMS key.
- **CloudTrail Logging:** S3 object-level events are logged for compliance.
- **Lifecycle Management:** Objects are automatically expired after a configurable number of days.
- **Versioning & MFA Delete:** Versioning is enabled; MFA Delete must be enabled manually (see output).
- **Object Ownership:** Recommended to use `BucketOwnerEnforced` for modern security.

---

## MFA Delete Manual Step

Terraform cannot enable MFA Delete due to AWS API limitations.  
**After creation, enable MFA Delete with:**

```sh
aws s3api put-bucket-versioning --bucket <bucket-name> --versioning-configuration Status=Enabled,MFADelete=Enabled --mfa "SERIAL_NUMBER MFA_CODE"
```
Replace `<bucket-name>`, `SERIAL_NUMBER`, and `MFA_CODE` with your values.

---

## Best Practices

- Use a unique workspace per environment (e.g., `dev`, `stage`, `prod`).
- Never use public ACLs or policies.
- Use [Terraform Cloud](https://developer.hashicorp.com/terraform/cloud-docs) or [Terraform Enterprise](https://developer.hashicorp.com/terraform/enterprise) for governance and policy enforcement.
- For advanced secrets management, integrate with [HashiCorp Vault](https://developer.hashicorp.com/vault/docs/secrets/aws).

---

## References

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform regexreplace() Function](https://developer.hashicorp.com/terraform/language/functions/regexreplace)
- [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [AWS S3 MFA Delete](https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiFactorAuthenticationDelete.html)
- [HashiCorp Validated Designs](https://developer.hashicorp.com/validated-designs/terraform-operating-guides-adoption)

---
