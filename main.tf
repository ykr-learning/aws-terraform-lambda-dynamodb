provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_s3_bucket" "b" {
  bucket = "tp6-lambda-dynamodb-bucket"

  tags = {
    tp = "tp6"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

data "aws_iam_policy_document" "lambda_assume_role_policy"{
  statement {
    effect  = "Allow"
    actions = [                
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
      ]
    resources = ["arn:aws:logs:*:*:*"]
    }
  statement {
    effect  = "Allow"
    actions = [                
        "ec2:Describe*",
        "ec2:Start*",
        "ec2:Stop*"
      ]
    resources = ["*"]
    }
}

resource "aws_iam_role" "iam_for_lambda_tp6" {
  name = "iam-for-lambda-tp6"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
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

  tags = {
    tp = "tp6"
  }

}