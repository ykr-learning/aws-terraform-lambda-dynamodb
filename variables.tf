variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
  default     = "tp6-lambda-dynamodb-bucket"
}
