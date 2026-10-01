provider "aws" {
  region = var.aws_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  sanitized_workspace_name = replace(terraform.workspace,"/[^a-zA-Z0-9-]/", "")
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

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
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

