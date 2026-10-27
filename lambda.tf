data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../cloud-resume-backend/src"
  output_path = "${path.module}/build/function.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project}-visitor-counter-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "update-visitor-count"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:UpdateItem"
      Resource = aws_dynamodb_table.visitor.arn
    }]
  })
}

resource "aws_lambda_function" "visitor" {
  function_name    = "${var.project}-visitor-counter"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor.name
    }
  }
}

resource "aws_lambda_function_url" "visitor" {
  function_name      = aws_lambda_function.visitor.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = [var.allowed_origin]
    allow_methods = ["GET"]
    allow_headers = ["content-type"]
  }
}

# Permission 1: allow the public to call the function URL
resource "aws_lambda_permission" "public_url" {
  statement_id           = "AllowPublicFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.visitor.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# Permission 2: allow the invoke itself, only when it comes through the URL
resource "aws_lambda_permission" "public_invoke" {
  statement_id             = "AllowPublicInvokeViaFunctionUrl"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.visitor.function_name
  principal                = "*"
  invoked_via_function_url = true
}