provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["$HOME/.aws/credentials"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_s3_bucket" "b" {
  bucket = var.bucket_name

  tags = {
    tp = "tp6"
  }
}

# Upload an object
resource "aws_s3_bucket_object" "file_instances_ids" {

  bucket = aws_s3_bucket.b.id

  key = var.file_instances_ids_name

  acl = "private" # or can be "public-read"

  source = "./${var.file_instances_ids_name}"

  etag = filemd5("./${var.file_instances_ids_name}")

}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "tp6_lambda_role_policy" {
  name = "tp6_lambda_role_policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:Describe*",
          "ec2:Start*",
          "ec2:Stop*",
          "s3:Get*",
          "s3:List*",
          "dynamodb:Put*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "iam_for_lambda_tp6" {
  name = "iam-for-lambda-tp6"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  managed_policy_arns = [aws_iam_policy.tp6_lambda_role_policy.arn]
}

data "archive_file" "python_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambda_code/lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "tp6_lambda" {
  function_name = "tp6_lambda"
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename = "lambda_function_payload.zip"
  role     = aws_iam_role.iam_for_lambda_tp6.arn
  handler  = "lambda_function.lambda_handler"
  timeout  = 120
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256

  runtime = "python3.9"


  environment {
    variables = {
      S3_BUCKET      = "${var.bucket_name}"
      DYNAMODB_TABLE = "${var.dynamodb_table_name}"
    }
  }

  tags = {
    tp = "tp6"
  }
}

resource "aws_dynamodb_table" "tp6_dynamo_table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = "5"
  write_capacity = "5"
  attribute {
    name = "id"
    type = "S"
  }
  hash_key = "id"
}
