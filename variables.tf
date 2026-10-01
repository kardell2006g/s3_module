variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "email" {
  description = "The email to tag resources with"
  type        = string
}

variable "bucket_acl" {
  description = "The canned ACL to apply to the S3 bucket"
  type        = string
  validation {
    condition = contains([
      "private",
      "public-read",
      "public-read-write",
      "authenticated-read",
      "log-delivery-write",
      "bucket-owner-read",
      "bucket-owner-full-control",
      "aws-exec-read"
    ], var.bucket_acl)
    error_message = "Invalid ACL. Must be one of: private, public-read, public-read-write, authenticated-read, log-delivery-write, bucket-owner-read, bucket-owner-full-control, aws-exec-read."
  }
}
