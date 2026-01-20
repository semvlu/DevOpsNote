variable "aws_region" {
  type        = string
  default     = "eu-north-1"
  description = "The AWS region your resources will be deployed"
}

variable "aws_az" {
  type        = string
  default     = "eu-north-1a"
  description = "The AWS Availability Zone"
}