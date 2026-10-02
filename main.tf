provider "aws" {
  region = var.aws_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_pet" "cloudtrail_name" {
  length    = 2
  separator = "-"
}

locals {
  sanitized_workspace_name = replace(terraform.workspace,"/[^a-zA-Z0-9-]/", "")
  bucket_name              = "${local.sanitized_workspace_name}-${random_id.suffix.hex}"
  object_key               = local.sanitized_workspace_name

  effective_cloudtrail_trail_name = (
    var.cloudtrail_trail_name != "" ?
    var.cloudtrail_trail_name :
    "cloudtrail-${random_pet.cloudtrail_name.id}"
  )
}

resource "aws_kms_key" "bucket_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name
  tags = {
    Workspace = local.sanitized_workspace_name
    Email     = var.email
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status     = "Enabled"
    # mfa_delete = "Enabled" # Must be enabled manually via CLI
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

resource "aws_s3_bucket_lifecycle_configuration" "expiration" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "expire-objects"
    status = "Enabled"

    expiration {
      days = var.target_expiration_days
    }
  }
}

resource "aws_cloudtrail" "s3_trail" {
  name                          = local.effective_cloudtrail_trail_name
  s3_bucket_name                = aws_s3_bucket.bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}

data "aws_cloudtrail" "selected" {
  name = aws_cloudtrail.s3_trail.name
}

resource "aws_s3_bucket_policy" "combined" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # SSL enforcement
      {
        Sid       = "DenyUnEncryptedTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [
          "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      # CloudTrail PutObject
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = data.aws_cloudtrail.selected.arn
          }
        }
      },
      # CloudTrail GetBucketAcl
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = data.aws_cloudtrail.selected.arn
          }
        }
      },
      # CloudTrail ListBucket
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}"
        Condition = {
          StringLike = {
            "s3:prefix" = ["AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "s3_data_events" {
  name        = "s3-data-events"
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["AWS API Call via CloudTrail"]
  })
}
