# The /api/order/* backend. Role name starts with "aws-api-gateway-" because that is
# the only IAM prefix the deploy role from aws-foundation may manage.

data "archive_file" "order" {
  type        = "zip"
  source_dir  = "${path.module}/src/order"
  output_path = "${path.module}/.build/order.zip"
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "order" {
  name               = "aws-api-gateway-order-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy_attachment" "order_logs" {
  role       = aws_iam_role.order.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "order" {
  function_name    = "aws-api-gateway-order"
  role             = aws_iam_role.order.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.order.output_path
  source_code_hash = data.archive_file.order.output_base64sha256
}

resource "aws_lambda_permission" "order" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
