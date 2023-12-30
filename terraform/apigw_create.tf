##########
# CREATE #
##########

resource "aws_api_gateway_method" "user_post" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_resource.id
  http_method   = "POST"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_method_settings" "api_gateway_settings_post" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "${aws_api_gateway_resource.user_resource.path_part}/${aws_api_gateway_method.user_post.http_method}"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "dynamodb_post" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_resource.id
  http_method             = aws_api_gateway_method.user_post.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.region}:dynamodb:action/PutItem"
  credentials             = aws_iam_role.api_gateway_dynamodb_role.arn

  request_templates = {
    "application/json" = jsonencode({
      "TableName" = "AADemo_UserTable",
      # Note: Do not store sensitive data in a plaintext DB!
      "Item" = {
        "_pk0"       = { "S" = "$input.path('$.starship')" },
        "_sk0"       = { "S" = "$input.path('$.name')" },
        "email"      = { "S" = "$input.path('$.email')" },
        "subscribed" = { "BOOL" = "$input.path('$.subscribed')" }
      }
    })
  }
}

resource "aws_api_gateway_method_response" "user_post_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = aws_api_gateway_method.user_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "dynamodb_post_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = aws_api_gateway_method.user_post.http_method
  status_code = aws_api_gateway_method_response.user_post_200.status_code
}
