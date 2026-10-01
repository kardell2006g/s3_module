variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "email" {
  description = "The email to tag resources with"
  type        = string
}

variable "days_deletion" {
  description = "Days until objects deleted from the S3 bucket"
  type        = number
  validation {
    
    ],
    error_message = "Invalid must be a number between 0-365"
  }
}
