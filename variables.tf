variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "email" {
  description = "The email to tag resources with"
  type        = string
}

variable "target_expiration_days" {
  description = "Number of days after which objects expire"
  type        = number
  default     = 30
  validation {
    condition     = var.target_expiration_days >= 1 && var.target_expiration_days <= 365
    error_message = "Expiration days must be between 1 and 365."
  }
}
