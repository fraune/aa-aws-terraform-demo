##########
# DELETE #
##########

resource "aws_api_gateway_method" "user_delete" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_resource_pk_sk.id
  http_method   = "DELETE"
  authorization = "AWS_IAM"
  request_parameters = {
    "method.request.path.pk" = true
    "method.request.path.sk" = true
  }
}

resource "aws_api_gateway_method_settings" "api_gateway_settings_specific" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "${aws_api_gateway_resource.user_resource_pk_sk.path_part}/${aws_api_gateway_method.user_delete.http_method}"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}


resource "aws_api_gateway_integration" "dynamodb_delete" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_resource_pk_sk.id
  http_method             = aws_api_gateway_method.user_delete.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.region}:dynamodb:action/DeleteItem"
  credentials             = aws_iam_role.api_gateway_dynamodb_role.arn

  request_templates = {
    "application/json" = jsonencode({
      "TableName" : "AADemo_UserTable",
      "Version" : "2018-05-29",
      "Key" : {
        "_pk0" = { "S" = "$input.params('pk')" },
        "_sk0" = { "S" = "$input.params('sk')" }
      }
    })
  }
}

resource "aws_api_gateway_method_response" "user_delete_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource_pk_sk.id
  http_method = aws_api_gateway_method.user_delete.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "dynamodb_delete_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource_pk_sk.id
  http_method = aws_api_gateway_method.user_delete.http_method
  status_code = aws_api_gateway_method_response.user_delete_200.status_code
}

