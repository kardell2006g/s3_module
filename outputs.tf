output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.bucket.bucket
}

output "object_key" {
  description = "The key of the S3 object"
  value       = aws_s3_bucket_object.object.key
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for S3 bucket encryption"
  value       = aws_kms_key.bucket_key.arn
}

output "cloudtrail_trail_name" {
  value = local.effective_cloudtrail_trail_name
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.s3_trail.arn
}

output "mfa_delete_manual_step" {
  description = "Manual step required to enable MFA Delete on the S3 bucket"
  value = <<EOT
Terraform cannot enable MFA Delete due to AWS API limitations.
To enable MFA Delete, use the AWS CLI after bucket creation:

aws s3api put-bucket-versioning --bucket ${aws_s3_bucket.bucket.bucket} --versioning-configuration Status=Enabled,MFADelete=Enabled --mfa "SERIAL_NUMBER MFA_CODE"

Replace SERIAL_NUMBER with your MFA device serial and MFA_CODE with your current code.
EOT
}
