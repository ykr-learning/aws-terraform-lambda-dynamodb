variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
  default     = "tp6-bucket"
}

variable "file_instances_ids_name" {
  description = "File with instances ids"
  type        = string
  default     = "instances_ids.txt"
}

variable "dynamodb_table_name" {
  description = "Dynamodb table name"
  type        = string
  default     = "tp6_dynamo_table"
}
