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

provider "aws" {
  region = var.aws_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  sanitized_workspace_name = regexreplace(terraform.workspace, "[^a-zA-Z0-9-]", "")
  bucket_name              = "${local.sanitized_workspace_name}-${random_id.suffix.hex}"
  object_key               = local.sanitized_workspace_name
}

resource "aws_kms_key" "bucket_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name

  tags = {
    Workspace = local.sanitized_workspace_name
    Email     = var.email
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = var.bucket_acl
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.bucket_key.arn
    }
  }
}

resource "aws_s3_bucket_object" "object" {
  bucket                 = aws_s3_bucket.bucket.id
  key                    = local.object_key
  content                = "This is a test object"
  server_side_encryption = "aws:kms"
  kms_key_id             = aws_kms_key.bucket_key.arn

  tags = {
    Workspace = local.sanitized_workspace_name
    Email     = var.email
  }
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "object_key" {
  value = aws_s3_bucket_object.object.key
}
