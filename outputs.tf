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
