# HTTP API v2. Two routes under the /api basepath:
#   /api/order/*   -> Lambda proxy
#   /api/product/* -> external service (HTTP_PROXY)
#
# The greedy {proxy+} captures everything below each basepath. The $default stage with
# auto_deploy means no separate deployment resource — v2 handles it.

resource "aws_apigatewayv2_api" "this" {
  name          = "aws-api-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access.arn
    format = jsonencode({
      requestId = "$context.requestId"
      method    = "$context.httpMethod"
      path      = "$context.path"
      status    = "$context.status"
      error     = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_cloudwatch_log_group" "access" {
  name              = "/aws/apigateway/aws-api-gateway"
  retention_in_days = 14
}

# --- /api/order/* -> Lambda --------------------------------------------------

resource "aws_apigatewayv2_integration" "order" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.order.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "order" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/order/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.order.id}"
}

# --- /api/product/* -> external service --------------------------------------
# The {proxy} captured here is appended to the target URL, so /api/product/123
# becomes <product_service_url>/123.

resource "aws_apigatewayv2_integration" "product" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "${var.product_service_url}/{proxy}"

  request_parameters = {
    "overwrite:path" = "$request.path.proxy"
  }
}

resource "aws_apigatewayv2_route" "product" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /api/product/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.product.id}"
}

output "api_endpoint" {
  description = "Base URL. Routes live under /api/order/* and /api/product/*."
  value       = aws_apigatewayv2_api.this.api_endpoint
}
