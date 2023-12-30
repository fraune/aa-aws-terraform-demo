########
# READ #
########

resource "aws_api_gateway_method" "user_get" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_resource.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_method_settings" "api_gateway_settings_get" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "${aws_api_gateway_resource.user_resource.path_part}/${aws_api_gateway_method.user_get.http_method}"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "dynamodb_get" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_resource.id
  http_method             = aws_api_gateway_method.user_get.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.region}:dynamodb:action/Scan"
  credentials             = aws_iam_role.api_gateway_dynamodb_role.arn

  request_templates = {
    "application/json" = jsonencode({
      "TableName" = "AADemo_UserTable"
    })
  }
}

resource "aws_api_gateway_method_response" "user_get_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = aws_api_gateway_method.user_get.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "dynamodb_get_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = aws_api_gateway_method.user_get.http_method
  status_code = aws_api_gateway_method_response.user_get_200.status_code
}
